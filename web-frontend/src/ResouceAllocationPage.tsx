import React, { useState, useEffect } from "react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  LineChart,
  Line,
} from "recharts";
import {
  AlertCircle,
  CheckCircle,
  TrendingUp,
  Package,
  Users,
  Activity,
} from "lucide-react";

// Type definitions
interface ResourceInfo {
  allocated: number;
  demanded: number;
  percentage: number;
}

interface LocationAllocation {
  blankets: ResourceInfo;
  food: ResourceInfo;
  medicine: ResourceInfo;
  shelter_materials: ResourceInfo;
  water: ResourceInfo;
}

interface ResourceUtilization {
  available: number;
  used: number;
  utilization_percentage: number;
}

interface SatisfactionRate {
  priority: number;
  satisfaction_percentage: number;
}

interface ApiData {
  allocations: Record<string, LocationAllocation>;
  resource_utilization: Record<string, ResourceUtilization>;
  satisfaction_rates: Record<string, SatisfactionRate>;
  status: string;
  total_cost: number;
  unmet_demands: Record<string, any>;
}

interface ApiResponse {
  success: boolean;
  message: string;
  data: ApiData;
}

interface ChartData {
  name: string;
  available?: number;
  used?: number;
  utilization?: number;
  satisfaction?: number;
  priority?: number;
  value?: number;
  color?: string;
}

type TabType = "overview" | "allocations" | "utilization" | "satisfaction";

const ResourceAllocationDashboard: React.FC = () => {
  const [data, setData] = useState<ApiData | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<TabType>("overview");

  // Sample data from your API response
  const sampleData: ApiResponse = {
    success: true,
    message: "Sample data",
    data: {
      allocations: {
        KAD001: {
          blankets: { allocated: 30.0, demanded: 30.0, percentage: 100.0 },
          food: { allocated: 300.0, demanded: 300.0, percentage: 100.0 },
          medicine: { allocated: 50.0, demanded: 50.0, percentage: 100.0 },
          shelter_materials: {
            allocated: 20.0,
            demanded: 20.0,
            percentage: 100.0,
          },
          water: { allocated: 500.0, demanded: 500.0, percentage: 100.0 },
        },
        KAD002: {
          blankets: { allocated: 4880.0, demanded: 30.0, percentage: 16266.67 },
          food: { allocated: 300.0, demanded: 300.0, percentage: 100.0 },
          medicine: { allocated: 1800.0, demanded: 50.0, percentage: 3600.0 },
          shelter_materials: {
            allocated: 20.0,
            demanded: 20.0,
            percentage: 100.0,
          },
          water: { allocated: 500.0, demanded: 500.0, percentage: 100.0 },
        },
        KAD003: {
          blankets: { allocated: 30.0, demanded: 30.0, percentage: 100.0 },
          food: { allocated: 300.0, demanded: 300.0, percentage: 100.0 },
          medicine: { allocated: 50.0, demanded: 50.0, percentage: 100.0 },
          shelter_materials: {
            allocated: 2920.0,
            demanded: 20.0,
            percentage: 14600.0,
          },
          water: { allocated: 500.0, demanded: 500.0, percentage: 100.0 },
        },
        KOL001: {
          blankets: { allocated: 60.0, demanded: 60.0, percentage: 100.0 },
          food: { allocated: 9100.0, demanded: 600.0, percentage: 1516.67 },
          medicine: { allocated: 100.0, demanded: 100.0, percentage: 100.0 },
          shelter_materials: {
            allocated: 40.0,
            demanded: 40.0,
            percentage: 100.0,
          },
          water: { allocated: 48500.0, demanded: 1000.0, percentage: 4850.0 },
        },
      },
      resource_utilization: {
        blankets: {
          available: 5000,
          used: 5000.0,
          utilization_percentage: 100.0,
        },
        food: {
          available: 10000,
          used: 10000.0,
          utilization_percentage: 100.0,
        },
        medicine: {
          available: 2000,
          used: 2000.0,
          utilization_percentage: 100.0,
        },
        shelter_materials: {
          available: 3000,
          used: 3000.0,
          utilization_percentage: 100.0,
        },
        water: {
          available: 50000,
          used: 50000.0,
          utilization_percentage: 100.0,
        },
      },
      satisfaction_rates: {
        KAD001: { priority: 0.25, satisfaction_percentage: 100.0 },
        KAD002: { priority: 0.3, satisfaction_percentage: 833.33 },
        KAD003: { priority: 0.2, satisfaction_percentage: 422.22 },
        KOL001: { priority: 0.5, satisfaction_percentage: 3211.11 },
      },
      status: "Optimal",
      total_cost: 0,
      unmet_demands: {},
    },
  };

  useEffect(() => {
    // Fetch data from API
    const fetchData = async (): Promise<void> => {
      try {
        setLoading(true);
        setError(null);
        const response = await fetch(
          "http://localhost:5000/get-resource-allocation"
        );

        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }

        const result: ApiResponse = await response.json();

        if (result.success) {
          setData(result.data);
        } else {
          throw new Error(
            result.message || "API returned unsuccessful response"
          );
        }
      } catch (error) {
        console.error("Error fetching data:", error);
        const errorMessage =
          error instanceof Error ? error.message : "Unknown error occurred";
        setError(errorMessage);
        // Fallback to sample data if API call fails
        setData(sampleData.data);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">
            Loading resource allocation data...
          </p>
        </div>
      </div>
    );
  }

  if (error && !data) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <AlertCircle className="h-16 w-16 text-red-500 mx-auto mb-4" />
          <h2 className="text-xl font-semibold text-gray-900 mb-2">
            Error Loading Data
          </h2>
          <p className="text-gray-600 mb-4">{error}</p>
          <button
            onClick={() => window.location.reload()}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  if (!data) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <AlertCircle className="h-16 w-16 text-gray-500 mx-auto mb-4" />
          <h2 className="text-xl font-semibold text-gray-900 mb-2">
            No Data Available
          </h2>
          <p className="text-gray-600">
            Unable to load resource allocation data.
          </p>
        </div>
      </div>
    );
  }

  const getStatusColor = (status: string): string => {
    switch (status) {
      case "Optimal":
        return "text-green-600 bg-green-100";
      case "Warning":
        return "text-yellow-600 bg-yellow-100";
      case "Critical":
        return "text-red-600 bg-red-100";
      default:
        return "text-gray-600 bg-gray-100";
    }
  };

  const getSatisfactionColor = (percentage: number): string => {
    if (percentage >= 100) return "text-green-600";
    if (percentage >= 80) return "text-yellow-600";
    return "text-red-600";
  };

  const resourceColors: Record<string, string> = {
    blankets: "#3B82F6",
    food: "#10B981",
    medicine: "#F59E0B",
    shelter_materials: "#8B5CF6",
    water: "#06B6D4",
  };

  // Prepare chart data
  const resourceUtilizationData: ChartData[] = Object.entries(
    data.resource_utilization
  ).map(([resource, info]) => ({
    name: resource.replace("_", " ").toUpperCase(),
    available: info.available,
    used: info.used,
    utilization: info.utilization_percentage,
  }));

  const satisfactionData: ChartData[] = Object.entries(
    data.satisfaction_rates
  ).map(([location, info]) => ({
    name: location,
    satisfaction: Math.min(info.satisfaction_percentage, 200),
    priority: info.priority * 100,
  }));

  const allocationByResource: ChartData[] = Object.entries(
    data.resource_utilization
  ).map(([resource, info]) => ({
    name: resource.replace("_", " ").toUpperCase(),
    value: info.used,
    color: resourceColors[resource] || "#8884D8",
  }));

  const tabs: { id: TabType; label: string }[] = [
    { id: "overview", label: "Overview" },
    { id: "allocations", label: "Allocations" },
    { id: "utilization", label: "Utilization" },
    { id: "satisfaction", label: "Satisfaction" },
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">
                Resource Allocation Dashboard
              </h1>
              <p className="text-gray-600">
                Real-time resource management and allocation tracking
              </p>
              {error && (
                <div className="mt-2 flex items-center text-sm text-yellow-600">
                  <AlertCircle className="h-4 w-4 mr-1" />
                  <span>Using fallback data due to API error: {error}</span>
                </div>
              )}
            </div>
            <div
              className={`px-4 py-2 rounded-full ${getStatusColor(
                data.status
              )}`}
            >
              <div className="flex items-center space-x-2">
                <CheckCircle className="h-5 w-5" />
                <span className="font-semibold">{data.status}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Navigation Tabs */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
        <div className="border-b border-gray-200">
          <nav className="-mb-px flex space-x-8">
            {tabs.map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`py-2 px-1 border-b-2 font-medium text-sm ${
                  activeTab === tab.id
                    ? "border-blue-500 text-blue-600"
                    : "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
                }`}
              >
                {tab.label}
              </button>
            ))}
          </nav>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        {activeTab === "overview" && (
          <div className="space-y-6">
            {/* Key Metrics */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
              <div className="bg-white p-6 rounded-lg shadow-sm border">
                <div className="flex items-center">
                  <Package className="h-8 w-8 text-blue-600" />
                  <div className="ml-4">
                    <p className="text-sm font-medium text-gray-600">
                      Total Resources
                    </p>
                    <p className="text-2xl font-bold text-gray-900">
                      {Object.values(data.resource_utilization)
                        .reduce((sum, r) => sum + r.available, 0)
                        .toLocaleString()}
                    </p>
                  </div>
                </div>
              </div>

              <div className="bg-white p-6 rounded-lg shadow-sm border">
                <div className="flex items-center">
                  <Activity className="h-8 w-8 text-green-600" />
                  <div className="ml-4">
                    <p className="text-sm font-medium text-gray-600">
                      Resources Used
                    </p>
                    <p className="text-2xl font-bold text-gray-900">
                      {Object.values(data.resource_utilization)
                        .reduce((sum, r) => sum + r.used, 0)
                        .toLocaleString()}
                    </p>
                  </div>
                </div>
              </div>

              <div className="bg-white p-6 rounded-lg shadow-sm border">
                <div className="flex items-center">
                  <Users className="h-8 w-8 text-purple-600" />
                  <div className="ml-4">
                    <p className="text-sm font-medium text-gray-600">
                      Locations
                    </p>
                    <p className="text-2xl font-bold text-gray-900">
                      {Object.keys(data.allocations).length}
                    </p>
                  </div>
                </div>
              </div>

              <div className="bg-white p-6 rounded-lg shadow-sm border">
                <div className="flex items-center">
                  <TrendingUp className="h-8 w-8 text-orange-600" />
                  <div className="ml-4">
                    <p className="text-sm font-medium text-gray-600">
                      Avg Utilization
                    </p>
                    <p className="text-2xl font-bold text-gray-900">
                      {Math.round(
                        Object.values(data.resource_utilization).reduce(
                          (sum, r) => sum + r.utilization_percentage,
                          0
                        ) / Object.keys(data.resource_utilization).length
                      )}
                      %
                    </p>
                  </div>
                </div>
              </div>
            </div>

            {/* Charts Row */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <div className="bg-white p-6 rounded-lg shadow-sm border">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">
                  Resource Distribution
                </h3>
                <ResponsiveContainer width="100%" height={300}>
                  <PieChart>
                    <Pie
                      data={allocationByResource}
                      cx="50%"
                      cy="50%"
                      labelLine={false}
                      label={({ name, percent }: any) =>
                        `${name} ${(percent * 100).toFixed(0)}%`
                      }
                      outerRadius={80}
                      fill="#8884d8"
                      dataKey="value"
                    >
                      {allocationByResource.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} />
                      ))}
                    </Pie>
                    <Tooltip />
                  </PieChart>
                </ResponsiveContainer>
              </div>

              <div className="bg-white p-6 rounded-lg shadow-sm border">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">
                  Location Satisfaction Rates
                </h3>
                <ResponsiveContainer width="100%" height={300}>
                  <BarChart data={satisfactionData}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" />
                    <YAxis />
                    <Tooltip
                      formatter={(value: any) => [
                        `${value.toFixed(1)}%`,
                        "Satisfaction",
                      ]}
                    />
                    <Bar dataKey="satisfaction" fill="#3B82F6" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
          </div>
        )}

        {activeTab === "allocations" && (
          <div className="space-y-6">
            {Object.entries(data.allocations).map(([location, resources]) => (
              <div
                key={location}
                className="bg-white rounded-lg shadow-sm border overflow-hidden"
              >
                <div className="px-6 py-4 bg-gray-50 border-b">
                  <h3 className="text-lg font-semibold text-gray-900">
                    {location}
                  </h3>
                  <p className="text-sm text-gray-600">
                    Priority:{" "}
                    {(
                      data.satisfaction_rates[location]?.priority * 100 || 0
                    ).toFixed(0)}
                    % | Satisfaction:{" "}
                    <span
                      className={getSatisfactionColor(
                        data.satisfaction_rates[location]
                          ?.satisfaction_percentage || 0
                      )}
                    >
                      {(
                        data.satisfaction_rates[location]
                          ?.satisfaction_percentage || 0
                      ).toFixed(1)}
                      %
                    </span>
                  </p>
                </div>
                <div className="p-6">
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
                    {Object.entries(resources).map(([resource, info]) => (
                      <div key={resource} className="border rounded-lg p-4">
                        <h4 className="font-medium text-gray-900 capitalize mb-2">
                          {resource.replace("_", " ")}
                        </h4>
                        <div className="space-y-2 text-sm">
                          <div className="flex justify-between">
                            <span className="text-gray-600">Demanded:</span>
                            <span className="font-medium">{info.demanded}</span>
                          </div>
                          <div className="flex justify-between">
                            <span className="text-gray-600">Allocated:</span>
                            <span className="font-medium">
                              {info.allocated}
                            </span>
                          </div>
                          <div className="flex justify-between">
                            <span className="text-gray-600">Fulfillment:</span>
                            <span
                              className={`font-medium ${getSatisfactionColor(
                                info.percentage
                              )}`}
                            >
                              {info.percentage.toFixed(1)}%
                            </span>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {activeTab === "utilization" && (
          <div className="bg-white rounded-lg shadow-sm border">
            <div className="px-6 py-4 border-b">
              <h3 className="text-lg font-semibold text-gray-900">
                Resource Utilization
              </h3>
            </div>
            <div className="p-6">
              <ResponsiveContainer width="100%" height={400}>
                <BarChart data={resourceUtilizationData} layout="horizontal">
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis type="number" />
                  <YAxis dataKey="name" type="category" width={150} />
                  <Tooltip />
                  <Bar dataKey="available" fill="#E5E7EB" name="Available" />
                  <Bar dataKey="used" fill="#3B82F6" name="Used" />
                </BarChart>
              </ResponsiveContainer>

              <div className="mt-6 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
                {Object.entries(data.resource_utilization).map(
                  ([resource, info]) => (
                    <div
                      key={resource}
                      className="border rounded-lg p-4 text-center"
                    >
                      <h4 className="font-medium text-gray-900 capitalize mb-2">
                        {resource.replace("_", " ")}
                      </h4>
                      <div className="text-2xl font-bold text-blue-600 mb-1">
                        {info.utilization_percentage.toFixed(0)}%
                      </div>
                      <div className="text-sm text-gray-600">
                        {info.used.toLocaleString()} /{" "}
                        {info.available.toLocaleString()}
                      </div>
                    </div>
                  )
                )}
              </div>
            </div>
          </div>
        )}

        {activeTab === "satisfaction" && (
          <div className="bg-white rounded-lg shadow-sm border">
            <div className="px-6 py-4 border-b">
              <h3 className="text-lg font-semibold text-gray-900">
                Satisfaction Analysis
              </h3>
            </div>
            <div className="p-6">
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <div>
                  <ResponsiveContainer width="100%" height={300}>
                    <LineChart data={satisfactionData}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="name" />
                      <YAxis />
                      <Tooltip />
                      <Line
                        type="monotone"
                        dataKey="satisfaction"
                        stroke="#3B82F6"
                        strokeWidth={2}
                      />
                      <Line
                        type="monotone"
                        dataKey="priority"
                        stroke="#10B981"
                        strokeWidth={2}
                      />
                    </LineChart>
                  </ResponsiveContainer>
                </div>

                <div className="space-y-4">
                  {Object.entries(data.satisfaction_rates).map(
                    ([location, info]) => (
                      <div key={location} className="border rounded-lg p-4">
                        <div className="flex justify-between items-center mb-2">
                          <h4 className="font-medium text-gray-900">
                            {location}
                          </h4>
                          <span
                            className={`px-2 py-1 rounded text-xs font-medium ${
                              info.satisfaction_percentage >= 100
                                ? "bg-green-100 text-green-800"
                                : info.satisfaction_percentage >= 80
                                ? "bg-yellow-100 text-yellow-800"
                                : "bg-red-100 text-red-800"
                            }`}
                          >
                            {info.satisfaction_percentage >= 100
                              ? "Satisfied"
                              : info.satisfaction_percentage >= 80
                              ? "Moderate"
                              : "Needs Attention"}
                          </span>
                        </div>
                        <div className="space-y-1 text-sm">
                          <div className="flex justify-between">
                            <span className="text-gray-600">
                              Priority Weight:
                            </span>
                            <span className="font-medium">
                              {(info.priority * 100).toFixed(0)}%
                            </span>
                          </div>
                          <div className="flex justify-between">
                            <span className="text-gray-600">
                              Satisfaction Rate:
                            </span>
                            <span
                              className={`font-medium ${getSatisfactionColor(
                                info.satisfaction_percentage
                              )}`}
                            >
                              {info.satisfaction_percentage.toFixed(1)}%
                            </span>
                          </div>
                        </div>
                      </div>
                    )
                  )}
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default ResourceAllocationDashboard;
