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
        # Create the problem - Changed to MAXIMIZE satisfaction instead of minimize penalty
        prob = pulp.LpProblem("SafeHouse_Resource_Allocation", pulp.LpMaximize)

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

        # Satisfaction ratio variables (0 to 1 for each safe house-resource pair)
        satisfaction = {}
        for sh in self.safe_houses:
            satisfaction[sh] = {}
            for resource in self.resources:
                satisfaction[sh][resource] = pulp.LpVariable(
                    f"sat_{sh}_{resource}",
                    lowBound=0,
                    upBound=1,  # Cannot exceed 100% satisfaction
                    cat='Continuous'
                )

        # NEW: Overall satisfaction variable for each safe house
        overall_satisfaction = {}
        for sh in self.safe_houses:
            overall_satisfaction[sh] = pulp.LpVariable(
                f"overall_sat_{sh}",
                lowBound=0,
                upBound=1,
                cat='Continuous'
            )

        # Objective function: Maximize weighted satisfaction
        total_satisfaction = pulp.lpSum([
            overall_satisfaction[sh] * self.priority_weights[sh]
            for sh in self.safe_houses
        ])

        prob += total_satisfaction

        # Constraints

        # 1. Supply constraints (can't allocate more than available)
        for resource in self.resources:
            prob += pulp.lpSum([x[sh][resource] for sh in self.safe_houses]) <= self.supply[
                resource], f"Supply_{resource}"

        # 2. Link allocation to satisfaction ratio
        for sh in self.safe_houses:
            for resource in self.resources:
                if self.demands[sh][resource] > 0:
                    prob += x[sh][resource] == satisfaction[sh][resource] * self.demands[sh][
                        resource], f"Satisfaction_Link_{sh}_{resource}"
                else:
                    prob += x[sh][resource] == 0, f"Zero_Demand_{sh}_{resource}"

        # 3. Overall satisfaction is the minimum of individual resource satisfactions
        for sh in self.safe_houses:
            for resource in self.resources:
                prob += overall_satisfaction[sh] <= satisfaction[sh][resource], f"Min_Satisfaction_{sh}_{resource}"

        # 4. Minimum allocation constraints (ensure each safe house gets at least 30% of needs)
        for sh in self.safe_houses:
            prob += overall_satisfaction[sh] >= 0.3, f"Min_Overall_{sh}"

        # 5. Fair distribution: Higher priority houses can get up to 100%, lower priority at least 50%
        for sh in self.safe_houses:
            min_satisfaction = max(0.5, 0.3 + (self.priority_weights[sh] - 1) * 0.1)
            prob += overall_satisfaction[sh] >= min_satisfaction, f"Fair_Distribution_{sh}"

        # Solve the problem
        prob.solve(pulp.PULP_CBC_CMD(msg=0))

        return prob, x, satisfaction, overall_satisfaction

    def get_results_dict(self, prob, x, satisfaction, overall_satisfaction):
        """Return results as a dictionary for API response"""
        results = {
            'status': pulp.LpStatus[prob.status],
            'total_satisfaction': prob.objective.value() if prob.objective.value() else 0,
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
                satisfaction_ratio = satisfaction[sh][resource].value() if satisfaction[sh][resource].value() else 0

                results['allocations'][sh][resource] = {
                    'allocated': round(allocated, 2),
                    'demanded': demanded,
                    'percentage': round(satisfaction_ratio * 100, 1)
                }

        # Unmet demand analysis
        for sh in self.safe_houses:
            results['unmet_demands'][sh] = {}
            for resource in self.resources:
                allocated = x[sh][resource].value() if x[sh][resource].value() else 0
                demanded = self.demands[sh][resource]
                unmet = max(0, demanded - allocated)
                if unmet > 0.01:  # Only show significant unmet demands
                    results['unmet_demands'][sh][resource] = round(unmet, 2)

        # Resource utilization
        for resource in self.resources:
            used = sum([x[sh][resource].value() if x[sh][resource].value() else 0
                        for sh in self.safe_houses])
            available = self.supply[resource]
            results['resource_utilization'][resource] = {
                'used': round(used, 2),
                'available': available,
                'utilization_percentage': round((used / available * 100), 1) if available > 0 else 0
            }

        # Satisfaction rates by safe house
        for sh in self.safe_houses:
            overall_sat = overall_satisfaction[sh].value() if overall_satisfaction[sh].value() else 0
            results['satisfaction_rates'][sh] = {
                'satisfaction_percentage': round(overall_sat * 100, 1),
                'priority': self.priority_weights[sh]
            }

        return results