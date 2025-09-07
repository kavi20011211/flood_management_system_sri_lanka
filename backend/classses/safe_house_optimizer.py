import pulp
import pandas as pd
import numpy as np


class SafeHouseOptimizer:
    def __init__(self):
        # safe house data
        self.safe_houses = []
        self.resources = []

        # resources demands (units needed per safe house)
        self.demands = {}

        # available supply
        self.supply = {}

        # priority weights (higher = more critical)
        self.priority_weights = {}

    # --- Safe Houses ---
    @property
    def safe_houses(self):
        return self._safe_houses

    @safe_houses.setter
    def safe_houses(self, houses):
        if not isinstance(houses, list):
            raise ValueError("safe_houses must be a list")
        self._safe_houses = houses

    # --- Resources ---
    @property
    def resources(self):
        return self._resources

    @resources.setter
    def resources(self, resources):
        if not isinstance(resources, list):
            raise ValueError("resources must be a list")
        self._resources = resources

    # --- Demands ---
    @property
    def demands(self):
        return self._demands

    @demands.setter
    def demands(self, demands):
        if not isinstance(demands, dict):
            raise ValueError("demands must be a dictionary")
        self._demands = demands

    # --- Supply ---
    @property
    def supply(self):
        return self._supply

    @supply.setter
    def supply(self, supply):
        if not isinstance(supply, dict):
            raise ValueError("supply must be a dictionary")
        self._supply = supply

    # --- Priority Weights ---
    @property
    def priority_weights(self):
        return self._priority_weights

    @priority_weights.setter
    def priority_weights(self, weights):
        if not isinstance(weights, dict):
            raise ValueError("priority_weights must be a dictionary")
        self._priority_weights = weights

    def solve_optimizer(self):
        # Create the problem
        prob = pulp.LpProblem("SafeHouse_Resource_Allocation", pulp.LpMinimize)

        # Decision Variables
        # x[sh][resource] = amount of resource allocated to safe house
        x = {}
        for sh in self.safe_houses:
            x[sh] = {}
            for resource in self.resources:
                x[sh][resource] = pulp.LpVariable(
                    f"x_{sh}_{resource}",
                    lowBound=0,
                    cat='Continuous'
                )

        # Binary variables for unmet demand penalty
        unmet = {}
        for sh in self.safe_houses:
            unmet[sh] = {}
            for resource in self.resources:
                unmet[sh][resource] = pulp.LpVariable(
                    f"unmet_{sh}_{resource}",
                    lowBound=0,
                    cat='Continuous'
                )

        # Objective function: Minimize unmet demand penalty
        unmet_demand_penalty = pulp.lpSum([
            unmet[sh][resource] * 1000 * self.priority_weights[sh]  # High penalty
            for sh in self.safe_houses
            for resource in self.resources
        ])

        prob += unmet_demand_penalty

        # Constraints

        # 1. Supply constraints (can't allocate more than available)
        for resource in self.resources:
            prob += pulp.lpSum([x[sh][resource] for sh in self.safe_houses]) <= self.supply[
                resource], f"Supply_{resource}"

        # 2. Demand satisfaction constraints (with slack for unmet demand)
        for sh in self.safe_houses:
            for resource in self.resources:
                prob += x[sh][resource] + unmet[sh][resource] >= self.demands[sh][
                    resource], f"Demand_{sh}_{resource}"

        # 3. Minimum allocation constraints (ensure each safe house gets at least something)
        for sh in self.safe_houses:
            for resource in self.resources:
                prob += x[sh][resource] >= 0.1 * self.demands[sh][resource], f"Min_{sh}_{resource}"

        # 4. Equity constraint (no safe house should get less than 60% of their needs)
        for sh in self.safe_houses:
            total_demand = sum(self.demands[sh].values())
            if total_demand > 0:  # Avoid division by zero
                total_allocated = pulp.lpSum([x[sh][resource] for resource in self.resources])
                prob += total_allocated >= 0.6 * total_demand, f"Equity_{sh}"

        # Solve the problem
        prob.solve(pulp.PULP_CBC_CMD(msg=0))

        return prob, x, unmet

    def get_results_dict(self, prob, x, unmet):
        """Return results as a dictionary for API response"""
        results = {
            'status': pulp.LpStatus[prob.status],
            'total_cost': prob.objective.value() if prob.objective.value() else 0,
            'allocations': {},
            'unmet_demands': {},
            'resource_utilization': {},
            'satisfaction_rates': {}
        }

        # Allocation results
        for sh in self.safe_houses:
            results['allocations'][sh] = {}
            for resource in self.resources:
                allocated = x[sh][resource].value() if x[sh][resource].value() else 0
                demanded = self.demands[sh][resource]
                results['allocations'][sh][resource] = {
                    'allocated': allocated,
                    'demanded': demanded,
                    'percentage': (allocated / demanded * 100) if demanded > 0 else 0
                }

        # Unmet demand analysis
        for sh in self.safe_houses:
            results['unmet_demands'][sh] = {}
            for resource in self.resources:
                unmet_val = unmet[sh][resource].value() if unmet[sh][resource].value() else 0
                if unmet_val > 0.01:  # Avoid tiny floating point values
                    results['unmet_demands'][sh][resource] = unmet_val

        # Resource utilization
        for resource in self.resources:
            used = sum([x[sh][resource].value() if x[sh][resource].value() else 0
                       for sh in self.safe_houses])
            available = self.supply[resource]
            results['resource_utilization'][resource] = {
                'used': used,
                'available': available,
                'utilization_percentage': (used / available * 100) if available > 0 else 0
            }

        # Satisfaction rates by safe house
        for sh in self.safe_houses:
            total_demand = sum(self.demands[sh].values())
            total_allocated = sum([x[sh][resource].value() if x[sh][resource].value() else 0
                                 for resource in self.resources])
            satisfaction = (total_allocated / total_demand * 100) if total_demand > 0 else 0
            results['satisfaction_rates'][sh] = {
                'satisfaction_percentage': satisfaction,
                'priority': self.priority_weights[sh]
            }

        return results