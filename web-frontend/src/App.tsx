import {
  BellIcon,
  Home,
  Menu,
  MessageSquare,
  Package,
  TrendingUp,
} from "lucide-react";
import FeedbackManagementDashboard from "./FeedbackManagement";
import ResourceAllocationDashboard from "./ResouceAllocationPage";
import ResourcePredictionDashboard from "./ResourcePredictionPage";
import { useState } from "react";
import RequestManagement from "./RequestManagement";

const HomePage = () => (
  <div className="p-8">
    <h1 className="text-4xl font-bold text-gray-800 mb-6">
      Dashboard Overview
    </h1>
    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div className="bg-gradient-to-br from-blue-500 to-blue-600 text-white rounded-lg p-6 shadow-lg">
        <div className="flex items-center justify-between mb-4">
          <MessageSquare className="w-8 h-8" />
          <span className="text-2xl font-bold">24</span>
        </div>
        <h3 className="text-lg font-semibold mb-2">Active Feedbacks</h3>
        <p className="text-blue-100">New feedback submissions</p>
      </div>

      <div className="bg-gradient-to-br from-green-500 to-green-600 text-white rounded-lg p-6 shadow-lg">
        <div className="flex items-center justify-between mb-4">
          <Package className="w-8 h-8" />
          <span className="text-2xl font-bold">87%</span>
        </div>
        <h3 className="text-lg font-semibold mb-2">Resource Allocation</h3>
        <p className="text-green-100">Current allocation efficiency</p>
      </div>

      <div className="bg-gradient-to-br from-purple-500 to-purple-600 text-white rounded-lg p-6 shadow-lg">
        <div className="flex items-center justify-between mb-4">
          <TrendingUp className="w-8 h-8" />
          <span className="text-2xl font-bold">↑ 12%</span>
        </div>
        <h3 className="text-lg font-semibold mb-2">Prediction Accuracy</h3>
        <p className="text-purple-100">Resource demand forecasting</p>
      </div>
    </div>

    <div className="mt-8 bg-white rounded-lg shadow-md p-6">
      <h2 className="text-2xl font-semibold text-gray-800 mb-4">
        Welcome to Your Dashboard
      </h2>
      <p className="text-gray-600 leading-relaxed">
        Navigate through the different sections using the navigation menu above.
        Each dashboard provides comprehensive insights and management tools for
        different aspects of your system:
      </p>
      <ul className="mt-4 space-y-2 text-gray-600">
        <li className="flex items-center">
          <MessageSquare className="w-4 h-4 mr-2 text-blue-500" />
          <strong>Feedback Management:</strong> Monitor and respond to user
          feedback
        </li>
        <li className="flex items-center">
          <Package className="w-4 h-4 mr-2 text-green-500" />
          <strong>Resource Allocation:</strong> Optimize resource distribution
        </li>
        <li className="flex items-center">
          <TrendingUp className="w-4 h-4 mr-2 text-purple-500" />
          <strong>Resource Prediction:</strong> Forecast future resource needs
        </li>
      </ul>
    </div>
  </div>
);

export default function App() {
  const [currentPage, setCurrentPage] = useState("home");
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  const navigation = [
    { id: "home", name: "Home", icon: Home },
    { id: "feedback", name: "Feedback Management", icon: MessageSquare },
    { id: "allocation", name: "Resource Allocation", icon: Package },
    { id: "prediction", name: "Resource Prediction", icon: TrendingUp },
    { id: "requests", name: "Requests Management", icon: BellIcon },
  ];

  const renderCurrentPage = () => {
    switch (currentPage) {
      case "home":
        return <HomePage />;
      case "feedback":
        return <FeedbackManagementDashboard />;
      case "allocation":
        return <ResourceAllocationDashboard />;
      case "prediction":
        return <ResourcePredictionDashboard />;
      case "requests":
        return <RequestManagement />;
      default:
        return <HomePage />;
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Navigation Header */}
      <nav className="bg-white shadow-lg border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            {/* Logo/Brand */}
            <div className="flex items-center">
              <div className="flex-shrink-0 flex items-center">
                <div className="w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg flex items-center justify-center">
                  <span className="text-white font-bold text-sm">FMS</span>
                </div>
                <span className="ml-2 text-xl font-bold text-gray-800">
                  Flood Management System Sri Lanka
                </span>
              </div>
            </div>

            {/* Desktop Navigation */}
            <div className="hidden md:block">
              <div className="ml-10 flex items-baseline space-x-4">
                {navigation.map((item) => {
                  const IconComponent = item.icon;
                  const isActive = currentPage === item.id;
                  return (
                    <button
                      key={item.id}
                      onClick={() => setCurrentPage(item.id)}
                      className={`px-3 py-2 rounded-md text-sm font-medium flex items-center space-x-2 transition-colors duration-200 ${
                        isActive
                          ? "bg-blue-100 text-blue-700 border-b-2 border-blue-500"
                          : "text-gray-600 hover:text-gray-900 hover:bg-gray-100"
                      }`}
                    >
                      <IconComponent className="w-4 h-4" />
                      <span>{item.name}</span>
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Mobile menu button */}
            <div className="md:hidden">
              <button
                onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
                className="inline-flex items-center justify-center p-2 rounded-md text-gray-600 hover:text-gray-900 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-blue-500"
              >
                <Menu className="w-6 h-6" />
              </button>
            </div>
          </div>
        </div>

        {/* Mobile Navigation Menu */}
        {isMobileMenuOpen && (
          <div className="md:hidden border-t border-gray-200">
            <div className="px-2 pt-2 pb-3 space-y-1 sm:px-3 bg-gray-50">
              {navigation.map((item) => {
                const IconComponent = item.icon;
                const isActive = currentPage === item.id;
                return (
                  <button
                    key={item.id}
                    onClick={() => {
                      setCurrentPage(item.id);
                      setIsMobileMenuOpen(false);
                    }}
                    className={`w-full text-left px-3 py-2 rounded-md text-base font-medium flex items-center space-x-3 transition-colors duration-200 ${
                      isActive
                        ? "bg-blue-100 text-blue-700"
                        : "text-gray-600 hover:text-gray-900 hover:bg-gray-100"
                    }`}
                  >
                    <IconComponent className="w-5 h-5" />
                    <span>{item.name}</span>
                  </button>
                );
              })}
            </div>
          </div>
        )}
      </nav>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto">{renderCurrentPage()}</main>

      {/* Footer */}
      <footer className="bg-white border-t border-gray-200 mt-12">
        <div className="max-w-7xl mx-auto py-4 px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center">
            <p className="text-sm text-gray-500">
              © 2025 Flood Management System Sri Lanka. All rights reserved.
            </p>
            <p className="text-sm text-gray-500">
              Current Page:{" "}
              <span className="font-medium text-gray-700 capitalize">
                {currentPage}
              </span>
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
}
