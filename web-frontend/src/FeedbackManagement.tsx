import React, { useState, useEffect } from "react";
import {
  MessageCircle,
  Reply,
  Send,
  AlertCircle,
  CheckCircle,
  RefreshCw,
  MessageSquare,
  Clock,
  User,
} from "lucide-react";

// Type definitions
interface Feedback {
  id: number;
  feedback: string;
  reply: string | null;
}

interface ReplyRequest {
  reply: string;
}

const FeedbackManagementDashboard: React.FC = () => {
  const [feedbacks, setFeedbacks] = useState<Feedback[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [replyingTo, setReplyingTo] = useState<number | null>(null);
  const [replyText, setReplyText] = useState<string>("");
  const [submittingReply, setSubmittingReply] = useState<boolean>(false);
  const [replySuccess, setReplySuccess] = useState<number | null>(null);
  const [filter, setFilter] = useState<"all" | "replied" | "pending">("all");

  // Fetch all feedbacks
  const fetchFeedbacks = async () => {
    try {
      setLoading(true);
      setError(null);
      const response = await fetch("http://localhost:5000/get-all-feedbacks");

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data: Feedback[] = await response.json();
      setFeedbacks(data);
    } catch (error) {
      console.error("Error fetching feedbacks:", error);
      const errorMessage =
        error instanceof Error ? error.message : "Unknown error occurred";
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  // Add reply to feedback
  const addReply = async (feedbackId: number, reply: string) => {
    try {
      setSubmittingReply(true);
      setError(null);

      const response = await fetch(
        `http://localhost:5000/add-a-reply?id=${feedbackId}`,
        {
          method: "PUT",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ reply }),
        }
      );

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      // Update the feedback in local state
      setFeedbacks((prev) =>
        prev.map((feedback) =>
          feedback.id === feedbackId ? { ...feedback, reply } : feedback
        )
      );

      // Reset reply state
      setReplyingTo(null);
      setReplyText("");
      setReplySuccess(feedbackId);

      // Clear success message after 3 seconds
      setTimeout(() => {
        setReplySuccess(null);
      }, 3000);
    } catch (error) {
      console.error("Error adding reply:", error);
      const errorMessage =
        error instanceof Error ? error.message : "Unknown error occurred";
      setError(errorMessage);
    } finally {
      setSubmittingReply(false);
    }
  };

  const handleReplySubmit = (feedbackId: number) => {
    if (!replyText.trim()) {
      setError("Reply cannot be empty");
      return;
    }
    addReply(feedbackId, replyText);
  };

  const handleCancelReply = () => {
    setReplyingTo(null);
    setReplyText("");
    setError(null);
  };

  const getFilteredFeedbacks = (): Feedback[] => {
    switch (filter) {
      case "replied":
        return feedbacks.filter(
          (feedback) => feedback.reply !== null && feedback.reply.trim() !== ""
        );
      case "pending":
        return feedbacks.filter(
          (feedback) => feedback.reply === null || feedback.reply.trim() === ""
        );
      default:
        return feedbacks;
    }
  };

  const getStatsData = () => {
    const total = feedbacks.length;
    const replied = feedbacks.filter(
      (f) => f.reply !== null && f.reply.trim() !== ""
    ).length;
    const pending = total - replied;
    const responseRate = total > 0 ? Math.round((replied / total) * 100) : 0;

    return { total, replied, pending, responseRate };
  };

  useEffect(() => {
    fetchFeedbacks();
  }, []);

  if (loading && feedbacks.length === 0) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading feedbacks...</p>
        </div>
      </div>
    );
  }

  const stats = getStatsData();
  const filteredFeedbacks = getFilteredFeedbacks();

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">
                Feedback Management
              </h1>
              <p className="text-gray-600">
                Manage user feedbacks and responses
              </p>
            </div>
            <button
              onClick={fetchFeedbacks}
              disabled={loading}
              className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50"
            >
              <RefreshCw
                className={`h-4 w-4 mr-2 ${loading ? "animate-spin" : ""}`}
              />
              Refresh
            </button>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
          <div className="bg-white p-6 rounded-lg shadow-sm border">
            <div className="flex items-center">
              <div className="p-2 bg-blue-100 rounded-lg">
                <MessageSquare className="h-6 w-6 text-blue-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">
                  Total Feedbacks
                </p>
                <p className="text-2xl font-bold text-gray-900">
                  {stats.total}
                </p>
              </div>
            </div>
          </div>

          <div className="bg-white p-6 rounded-lg shadow-sm border">
            <div className="flex items-center">
              <div className="p-2 bg-green-100 rounded-lg">
                <CheckCircle className="h-6 w-6 text-green-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">Replied</p>
                <p className="text-2xl font-bold text-gray-900">
                  {stats.replied}
                </p>
              </div>
            </div>
          </div>

          <div className="bg-white p-6 rounded-lg shadow-sm border">
            <div className="flex items-center">
              <div className="p-2 bg-yellow-100 rounded-lg">
                <Clock className="h-6 w-6 text-yellow-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">Pending</p>
                <p className="text-2xl font-bold text-gray-900">
                  {stats.pending}
                </p>
              </div>
            </div>
          </div>

          <div className="bg-white p-6 rounded-lg shadow-sm border">
            <div className="flex items-center">
              <div className="p-2 bg-purple-100 rounded-lg">
                <MessageCircle className="h-6 w-6 text-purple-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600">
                  Response Rate
                </p>
                <p className="text-2xl font-bold text-gray-900">
                  {stats.responseRate}%
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Filter Tabs */}
        <div className="bg-white rounded-lg shadow-sm border mb-6">
          <div className="px-6 py-4 border-b border-gray-200">
            <div className="flex space-x-4">
              <button
                onClick={() => setFilter("all")}
                className={`px-4 py-2 rounded-lg text-sm font-medium ${
                  filter === "all"
                    ? "bg-blue-100 text-blue-700"
                    : "text-gray-600 hover:text-gray-900 hover:bg-gray-50"
                }`}
              >
                All ({stats.total})
              </button>
              <button
                onClick={() => setFilter("pending")}
                className={`px-4 py-2 rounded-lg text-sm font-medium ${
                  filter === "pending"
                    ? "bg-yellow-100 text-yellow-700"
                    : "text-gray-600 hover:text-gray-900 hover:bg-gray-50"
                }`}
              >
                Pending ({stats.pending})
              </button>
              <button
                onClick={() => setFilter("replied")}
                className={`px-4 py-2 rounded-lg text-sm font-medium ${
                  filter === "replied"
                    ? "bg-green-100 text-green-700"
                    : "text-gray-600 hover:text-gray-900 hover:bg-gray-50"
                }`}
              >
                Replied ({stats.replied})
              </button>
            </div>
          </div>
        </div>

        {/* Error Display */}
        {error && (
          <div className="mb-6 flex items-center p-4 bg-red-50 border border-red-200 rounded-lg">
            <AlertCircle className="h-5 w-5 text-red-400 mr-2" />
            <span className="text-sm text-red-700">{error}</span>
            <button
              onClick={() => setError(null)}
              className="ml-auto text-red-400 hover:text-red-600"
            >
              ×
            </button>
          </div>
        )}

        {/* Feedbacks List */}
        {filteredFeedbacks.length === 0 ? (
          <div className="bg-white rounded-lg shadow-sm border p-12 text-center">
            <MessageCircle className="h-16 w-16 text-gray-300 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">
              {filter === "all"
                ? "No Feedbacks Available"
                : filter === "pending"
                ? "No Pending Feedbacks"
                : "No Replied Feedbacks"}
            </h3>
            <p className="text-gray-600">
              {filter === "all"
                ? "No user feedbacks have been submitted yet."
                : filter === "pending"
                ? "All feedbacks have been replied to."
                : "No feedbacks have replies yet."}
            </p>
          </div>
        ) : (
          <div className="space-y-4">
            {filteredFeedbacks.map((feedback) => (
              <div
                key={feedback.id}
                className="bg-white rounded-lg shadow-sm border overflow-hidden"
              >
                {/* Success Message */}
                {replySuccess === feedback.id && (
                  <div className="flex items-center p-3 bg-green-50 border-b border-green-200">
                    <CheckCircle className="h-4 w-4 text-green-400 mr-2" />
                    <span className="text-sm text-green-700">
                      Reply added successfully!
                    </span>
                  </div>
                )}

                <div className="p-6">
                  {/* Feedback Header */}
                  <div className="flex items-start justify-between mb-4">
                    <div className="flex items-center">
                      <div className="p-2 bg-gray-100 rounded-full">
                        <User className="h-5 w-5 text-gray-600" />
                      </div>
                      <div className="ml-3">
                        <p className="text-sm font-medium text-gray-900">
                          User Feedback #{feedback.id}
                        </p>
                        <div className="flex items-center mt-1">
                          {feedback.reply ? (
                            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                              <CheckCircle className="h-3 w-3 mr-1" />
                              Replied
                            </span>
                          ) : (
                            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                              <Clock className="h-3 w-3 mr-1" />
                              Pending Reply
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Feedback Content */}
                  <div className="bg-gray-50 rounded-lg p-4 mb-4">
                    <p className="text-gray-900">{feedback.feedback}</p>
                  </div>

                  {/* Existing Reply */}
                  {feedback.reply && (
                    <div className="bg-blue-50 border-l-4 border-blue-400 p-4 mb-4">
                      <div className="flex items-center mb-2">
                        <Reply className="h-4 w-4 text-blue-600 mr-2" />
                        <span className="text-sm font-medium text-blue-900">
                          Admin Reply
                        </span>
                      </div>
                      <p className="text-blue-800">{feedback.reply}</p>
                    </div>
                  )}

                  {/* Reply Actions */}
                  {replyingTo === feedback.id ? (
                    <div className="border-t pt-4">
                      <div className="space-y-3">
                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-2">
                            Your Reply
                          </label>
                          <textarea
                            value={replyText}
                            onChange={(e) => setReplyText(e.target.value)}
                            className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                            rows={3}
                            placeholder="Type your reply here..."
                          />
                        </div>
                        <div className="flex space-x-3">
                          <button
                            onClick={() => handleReplySubmit(feedback.id)}
                            disabled={submittingReply || !replyText.trim()}
                            className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
                          >
                            {submittingReply ? (
                              <>
                                <div className="animate-spin -ml-1 mr-2 h-4 w-4 border-2 border-white border-t-transparent rounded-full"></div>
                                Sending...
                              </>
                            ) : (
                              <>
                                <Send className="h-4 w-4 mr-2" />
                                Send Reply
                              </>
                            )}
                          </button>
                          <button
                            onClick={handleCancelReply}
                            disabled={submittingReply}
                            className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-gray-500"
                          >
                            Cancel
                          </button>
                        </div>
                      </div>
                    </div>
                  ) : (
                    <div className="flex justify-end border-t pt-4">
                      <button
                        onClick={() => {
                          setReplyingTo(feedback.id);
                          setReplyText(feedback.reply || "");
                          setError(null);
                        }}
                        className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
                      >
                        <Reply className="h-4 w-4 mr-2" />
                        {feedback.reply ? "Update Reply" : "Add Reply"}
                      </button>
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default FeedbackManagementDashboard;
