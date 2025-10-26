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

        # Resource importance weights (how critical each resource is)
        self.resource_weights = {
            'water': 0.35,
            'food': 0.30,
            'medicine': 0.20,
            'shelter_materials': 0.10,
            'blankets': 0.05
        }

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
        # Create the problem - Maximize weighted satisfaction
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

        # Overall satisfaction variable for each safe house (weighted average)
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

        # 3. Overall satisfaction is WEIGHTED AVERAGE of individual resource satisfactions
        for sh in self.safe_houses:
            prob += overall_satisfaction[sh] == pulp.lpSum([
                satisfaction[sh][resource] * self.resource_weights.get(resource, 1.0 / len(self.resources))
                for resource in self.resources
            ]), f"Weighted_Satisfaction_{sh}"

        # 4. Minimum allocation constraints - adaptive to available supply
        # Calculate what's actually achievable per resource
        min_achievable = {}
        for resource in self.resources:
            total_demand = sum([self.demands[sh][resource] for sh in self.safe_houses])
            if total_demand > 0:
                min_achievable[resource] = min(1.0, self.supply[resource] / total_demand)
            else:
                min_achievable[resource] = 1.0

        # Set minimum overall satisfaction based on what's actually possible
        for sh in self.safe_houses:
            prob += overall_satisfaction[sh] >= 0.20, f"Min_Overall_{sh}"

        # 5. FIXED: Equal priority = Equal satisfaction
        # Group safe houses by priority level
        priority_groups = {}
        for sh in self.safe_houses:
            priority = self.priority_weights[sh]
            if priority not in priority_groups:
                priority_groups[priority] = []
            priority_groups[priority].append(sh)

        # Ensure all safe houses in the same priority group get equal satisfaction
        for priority, houses in priority_groups.items():
            if len(houses) > 1:
                # Set all houses in this priority group to have equal overall satisfaction
                reference_house = houses[0]
                for sh in houses[1:]:
                    prob += overall_satisfaction[sh] == overall_satisfaction[reference_house], \
                            f"Equal_Priority_{priority}_{sh}_eq_{reference_house}"

        # 6. Priority ordering: Higher priority should get better satisfaction
        sorted_priorities = sorted(priority_groups.keys(), reverse=True)
        for i in range(len(sorted_priorities) - 1):
            high_priority = sorted_priorities[i]
            low_priority = sorted_priorities[i + 1]

            # Use representatives from each group
            high_rep = priority_groups[high_priority][0]
            low_rep = priority_groups[low_priority][0]

            # Higher priority gets at least 5% more satisfaction
            priority_diff = high_priority - low_priority
            bonus = min(0.15, priority_diff * 0.05)  # 5% per priority level, cap at 15%

            prob += overall_satisfaction[high_rep] >= \
                    overall_satisfaction[low_rep] + bonus, \
                    f"Priority_Order_{high_priority}_over_{low_priority}"

        # 7. ADAPTIVE: Critical resources minimum threshold
        # Only enforce minimums when supply allows
        for sh in self.safe_houses:
            for resource in ['water', 'food']:
                if resource in self.resources:
                    # Use adaptive threshold based on available supply
                    # For critically scarce resources, lower the threshold
                    if min_achievable[resource] < 0.5:
                        # Severe shortage - use proportional minimum
                        threshold = max(0.15, min_achievable[resource] * 0.6)
                    else:
                        # Adequate supply - use higher minimum
                        threshold = 0.40

                    prob += satisfaction[sh][resource] >= threshold, \
                            f"Critical_Min_{sh}_{resource}"

        # 8. CRITICAL FIX: Full allocation for abundant resources
        # If a resource has supply >= total demand, allocate 100% to everyone
        for resource in self.resources:
            if min_achievable[resource] >= 1.0:  # Supply meets or exceeds total demand
                for sh in self.safe_houses:
                    if self.demands[sh][resource] > 0:
                        prob += satisfaction[sh][resource] == 1.0, \
                                f"Full_Allocation_{sh}_{resource}"

        # Solve the problem
        status = prob.solve(pulp.PULP_CBC_CMD(msg=0))

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
                'priority': self.priority_weights[sh],
                'resource_breakdown': {}
            }

            # Add individual resource satisfaction for transparency
            for resource in self.resources:
                sat_val = satisfaction[sh][resource].value() if satisfaction[sh][resource].value() else 0
                results['satisfaction_rates'][sh]['resource_breakdown'][resource] = round(sat_val * 100, 1)

        return results