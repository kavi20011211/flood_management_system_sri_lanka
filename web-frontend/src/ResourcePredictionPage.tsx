import React, { useState } from "react";
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
} from "recharts";
import {
  Send,
  AlertCircle,
  CheckCircle,
  Activity,
  Users,
  Droplets,
  ShieldCheck,
  Pill,
  Package,
  Heart,
} from "lucide-react";

// Type definitions
interface PredictionRequest {
  severity: number;
  people_count: number;
}

interface PredictionResponse {
  prediction: number[][];
}

interface ResourceData {
  name: string;
  value: number;
  icon: React.ReactNode;
  color: string;
  unit: string;
}

interface ChartData {
  name: string;
  value: number;
  color: string;
}

const ResourcePredictionDashboard: React.FC = () => {
  const [formData, setFormData] = useState<PredictionRequest>({
    severity: 1,
    people_count: 100,
  });
  const [prediction, setPrediction] = useState<number[] | null>(null);
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [lastRequest, setLastRequest] = useState<PredictionRequest | null>(
    null
  );

  // Resource labels and their corresponding metadata
  const resourceLabels = [
    {
      name: "Bandages",
      key: "bandages",
      icon: <Heart className="h-5 w-5" />,
      color: "#EF4444",
      unit: "units",
    },
    {
      name: "ORS Kits",
      key: "ors_kits",
      icon: <Package className="h-5 w-5" />,
      color: "#F97316",
      unit: "kits",
    },
    {
      name: "Water",
      key: "water_liters",
      icon: <Droplets className="h-5 w-5" />,
      color: "#06B6D4",
      unit: "liters",
    },
    {
      name: "Mosquito Nets",
      key: "mosquito_nets",
      icon: <ShieldCheck className="h-5 w-5" />,
      color: "#10B981",
      unit: "nets",
    },
    {
      name: "Antibiotics",
      key: "antibiotics",
      icon: <Pill className="h-5 w-5" />,
      color: "#8B5CF6",
      unit: "doses",
    },
    {
      name: "First Aid Kits",
      key: "first_aids",
      icon: <Package className="h-5 w-5" />,
      color: "#F59E0B",
      unit: "kits",
    },
    {
      name: "Saline",
      key: "saline",
      icon: <Activity className="h-5 w-5" />,
      color: "#3B82F6",
      unit: "bottles",
    },
  ];

  const severityLevels = [
    { value: 1, label: "Low (1)", description: "Minor emergency" },
    { value: 2, label: "Moderate (2)", description: "Moderate emergency" },
    { value: 3, label: "High (3)", description: "Major emergency" },
  ];

  const handleInputChange = (field: keyof PredictionRequest, value: number) => {
    setFormData((prev) => ({
      ...prev,
      [field]: value,
    }));
    setError(null);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (formData.people_count <= 0) {
      setError("People count must be greater than 0");
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const url = `http://localhost:5000/get-prediction-resources-needs?severity=${formData.severity}&people_count=${formData.people_count}`;
      const response = await fetch(url);

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const result: PredictionResponse = await response.json();

      if (
        result.prediction &&
        result.prediction.length > 0 &&
        result.prediction[0].length === 7
      ) {
        setPrediction(result.prediction[0]);
        setLastRequest({ ...formData });
      } else {
        throw new Error("Invalid prediction response format");
      }
    } catch (error) {
      console.error("Error fetching prediction:", error);
      const errorMessage =
        error instanceof Error ? error.message : "Unknown error occurred";
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const getResourceData = (): ResourceData[] => {
    if (!prediction) return [];

    return resourceLabels.map((label, index) => ({
      name: label.name,
      value: Math.round(prediction[index]),
      icon: label.icon,
      color: label.color,
      unit: label.unit,
    }));
  };

  const getChartData = (): ChartData[] => {
    if (!prediction) return [];

    return resourceLabels.map((label, index) => ({
      name: label.name,
      value: Math.round(prediction[index]),
      color: label.color,
    }));
  };

  const getTotalResources = (): number => {
    if (!prediction) return 0;
    return prediction.reduce((sum, value) => sum + value, 0);
  };

  const getSeverityColor = (severity: number): string => {
    switch (severity) {
      case 1:
        return "bg-green-100 text-green-800";
      case 2:
        return "bg-blue-100 text-blue-800";
      case 3:
        return "bg-yellow-100 text-yellow-800";
      case 4:
        return "bg-orange-100 text-orange-800";
      case 5:
        return "bg-red-100 text-red-800";
      default:
        return "bg-gray-100 text-gray-800";
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="py-6">
            <h1 className="text-3xl font-bold text-gray-900">
              Resource Prediction Dashboard
            </h1>
            <p className="text-gray-600">
              Predict resource requirements based on emergency severity and
              affected population
            </p>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Left Panel - Input Form */}
          <div className="lg:col-span-1">
            <div className="bg-white rounded-lg shadow-sm border p-6">
              <div className="flex items-center mb-6">
                <Users className="h-6 w-6 text-blue-600 mr-2" />
                <h2 className="text-xl font-semibold text-gray-900">
                  Prediction Parameters
                </h2>
              </div>

              <form onSubmit={handleSubmit} className="space-y-6">
                {/* Severity Level */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-3">
                    Emergency Severity Level
                  </label>
                  <div className="space-y-2">
                    {severityLevels.map((level) => (
                      <div key={level.value} className="flex items-center">
                        <input
                          id={`severity-${level.value}`}
                          name="severity"
                          type="radio"
                          value={level.value}
                          checked={formData.severity === level.value}
                          onChange={(e) =>
                            handleInputChange(
                              "severity",
                              parseInt(e.target.value)
                            )
                          }
                          className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300"
                        />
                        <label
                          htmlFor={`severity-${level.value}`}
                          className="ml-3 block"
                        >
                          <div className="text-sm font-medium text-gray-700">
                            {level.label}
                          </div>
                          <div className="text-xs text-gray-500">
                            {level.description}
                          </div>
                        </label>
                      </div>
                    ))}
                  </div>
                </div>

                {/* People Count */}
                <div>
                  <label
                    htmlFor="people_count"
                    className="block text-sm font-medium text-gray-700 mb-2"
                  >
                    Affected Population
                  </label>
                  <div className="relative">
                    <Users className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
                    <input
                      type="number"
                      id="people_count"
                      min="1"
                      max="100000"
                      value={formData.people_count}
                      onChange={(e) =>
                        handleInputChange(
                          "people_count",
                          parseInt(e.target.value) || 0
                        )
                      }
                      className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                      placeholder="Enter number of people"
                    />
                  </div>
                  <p className="mt-1 text-xs text-gray-500">
                    Enter the estimated number of affected people
                  </p>
                </div>

                {/* Submit Button */}
                <button
                  type="submit"
                  disabled={loading}
                  className="w-full flex items-center justify-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {loading ? (
                    <>
                      <div className="animate-spin -ml-1 mr-2 h-4 w-4 border-2 border-white border-t-transparent rounded-full"></div>
                      Predicting...
                    </>
                  ) : (
                    <>
                      <Send className="h-4 w-4 mr-2" />
                      Get Prediction
                    </>
                  )}
                </button>

                {/* Error Display */}
                {error && (
                  <div className="flex items-center p-3 bg-red-50 border border-red-200 rounded-md">
                    <AlertCircle className="h-5 w-5 text-red-400 mr-2" />
                    <span className="text-sm text-red-700">{error}</span>
                  </div>
                )}
              </form>

              {/* Current Parameters Summary */}
              {lastRequest && (
                <div className="mt-6 pt-6 border-t border-gray-200">
                  <h3 className="text-sm font-medium text-gray-900 mb-3">
                    Last Prediction
                  </h3>
                  <div className="space-y-2">
                    <div className="flex justify-between items-center">
                      <span className="text-sm text-gray-600">Severity:</span>
                      <span
                        className={`px-2 py-1 rounded text-xs font-medium ${getSeverityColor(
                          lastRequest.severity
                        )}`}
                      >
                        Level {lastRequest.severity}
                      </span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-sm text-gray-600">Population:</span>
                      <span className="text-sm font-medium text-gray-900">
                        {lastRequest.people_count.toLocaleString()} people
                      </span>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Right Panel - Results */}
          <div className="lg:col-span-2">
            {!prediction ? (
              <div className="bg-white rounded-lg shadow-sm border p-12 text-center">
                <Package className="h-16 w-16 text-gray-300 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">
                  No Prediction Available
                </h3>
                <p className="text-gray-600">
                  Enter parameters and click "Get Prediction" to see resource
                  requirements
                </p>
              </div>
            ) : (
              <div className="space-y-6">
                {/* Summary Cards */}
                <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
                  <div className="bg-white p-4 rounded-lg shadow-sm border">
                    <div className="flex items-center">
                      <div className="p-2 bg-blue-100 rounded-lg">
                        <Package className="h-5 w-5 text-blue-600" />
                      </div>
                      <div className="ml-3">
                        <p className="text-sm font-medium text-gray-600">
                          Total Resources
                        </p>
                        <p className="text-lg font-bold text-gray-900">
                          {Math.round(getTotalResources()).toLocaleString()}
                        </p>
                      </div>
                    </div>
                  </div>

                  <div className="bg-white p-4 rounded-lg shadow-sm border">
                    <div className="flex items-center">
                      <div className="p-2 bg-green-100 rounded-lg">
                        <Users className="h-5 w-5 text-green-600" />
                      </div>
                      <div className="ml-3">
                        <p className="text-sm font-medium text-gray-600">
                          Population
                        </p>
                        <p className="text-lg font-bold text-gray-900">
                          {lastRequest?.people_count.toLocaleString()}
                        </p>
                      </div>
                    </div>
                  </div>

                  <div className="bg-white p-4 rounded-lg shadow-sm border">
                    <div className="flex items-center">
                      <div className="p-2 bg-yellow-100 rounded-lg">
                        <AlertCircle className="h-5 w-5 text-yellow-600" />
                      </div>
                      <div className="ml-3">
                        <p className="text-sm font-medium text-gray-600">
                          Severity
                        </p>
                        <p className="text-lg font-bold text-gray-900">
                          Level {lastRequest?.severity}
                        </p>
                      </div>
                    </div>
                  </div>

                  <div className="bg-white p-4 rounded-lg shadow-sm border">
                    <div className="flex items-center">
                      <div className="p-2 bg-purple-100 rounded-lg">
                        <Activity className="h-5 w-5 text-purple-600" />
                      </div>
                      <div className="ml-3">
                        <p className="text-sm font-medium text-gray-600">
                          Resource Types
                        </p>
                        <p className="text-lg font-bold text-gray-900">
                          {resourceLabels.length}
                        </p>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Resource Breakdown */}
                <div className="bg-white rounded-lg shadow-sm border">
                  <div className="px-6 py-4 border-b border-gray-200">
                    <h3 className="text-lg font-semibold text-gray-900">
                      Resource Requirements
                    </h3>
                  </div>
                  <div className="p-6">
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
                      {getResourceData().map((resource, index) => (
                        <div key={index} className="border rounded-lg p-4">
                          <div className="flex items-center justify-between mb-2">
                            <div className="flex items-center">
                              <div
                                className={`p-1 rounded`}
                                style={{
                                  backgroundColor: `${resource.color}20`,
                                }}
                              >
                                {React.cloneElement(
                                  resource.icon as React.ReactElement
                                  //   {
                                  //     style: { color: resource.color },
                                  //   }
                                )}
                              </div>
                              <span className="ml-2 font-medium text-gray-900">
                                {resource.name}
                              </span>
                            </div>
                          </div>
                          <div
                            className="text-2xl font-bold"
                            style={{ color: resource.color }}
                          >
                            {resource.value.toLocaleString()}
                          </div>
                          <div className="text-sm text-gray-500">
                            {resource.unit}
                          </div>
                        </div>
                      ))}
                    </div>

                    {/* Charts */}
                    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                      <div>
                        <h4 className="text-md font-medium text-gray-900 mb-4">
                          Resource Distribution
                        </h4>
                        <ResponsiveContainer width="100%" height={300}>
                          <PieChart>
                            <Pie
                              data={getChartData()}
                              cx="50%"
                              cy="50%"
                              labelLine={false}
                              label={({ name, percent }: any) =>
                                `${name} ${(percent * 100).toFixed(1)}%`
                              }
                              outerRadius={80}
                              fill="#8884d8"
                              dataKey="value"
                            >
                              {getChartData().map((entry, index) => (
                                <Cell
                                  key={`cell-${index}`}
                                  fill={entry.color}
                                />
                              ))}
                            </Pie>
                            <Tooltip
                              formatter={(value: any) => [
                                value.toLocaleString(),
                                "Units",
                              ]}
                            />
                          </PieChart>
                        </ResponsiveContainer>
                      </div>

                      <div>
                        <h4 className="text-md font-medium text-gray-900 mb-4">
                          Resource Quantities
                        </h4>
                        <ResponsiveContainer width="100%" height={300}>
                          <BarChart data={getChartData()} layout="vertical">
                            <CartesianGrid strokeDasharray="3 3" />
                            <XAxis type="number" />
                            <YAxis dataKey="name" type="category" width={80} />
                            <Tooltip
                              formatter={(value: any) => [
                                value.toLocaleString(),
                                "Units",
                              ]}
                            />
                            <Bar dataKey="value" fill="#3B82F6">
                              {getChartData().map((entry, index) => (
                                <Cell
                                  key={`cell-${index}`}
                                  fill={entry.color}
                                />
                              ))}
                            </Bar>
                          </BarChart>
                        </ResponsiveContainer>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Success Message */}
                <div className="flex items-center p-4 bg-green-50 border border-green-200 rounded-md">
                  <CheckCircle className="h-5 w-5 text-green-400 mr-2" />
                  <span className="text-sm text-green-700">
                    Prediction completed successfully for{" "}
                    {lastRequest?.people_count.toLocaleString()} people at
                    severity level {lastRequest?.severity}
                  </span>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default ResourcePredictionDashboard;
