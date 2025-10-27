import React, { useState } from "react";

interface SafeAreaData {
  area: string;
  safe_area: string;
  longitude: string;
  latitude: string;
  capacity: string;
  priority: string;
}

const AddSafeArea: React.FC = () => {
  const [formData, setFormData] = useState<SafeAreaData>({
    area: "",
    safe_area: "",
    longitude: "",
    latitude: "",
    capacity: "",
    priority: "",
  });

  const [submitLoading, setSubmitLoading] = useState(false);
  const [submitSuccess, setSubmitSuccess] = useState<string | null>(null);
  const [submitError, setSubmitError] = useState<string | null>(null);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitLoading(true);
    setSubmitError(null);
    setSubmitSuccess(null);

    try {
      const res = await fetch("http://localhost:5000/safe-area-create", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(formData),
      });

      const result = await res.json();

      if (res.ok) {
        setSubmitSuccess(result.message || "Safe area added successfully!");
        setFormData({
          area: "",
          safe_area: "",
          longitude: "",
          latitude: "",
          capacity: "",
          priority: "",
        });
      } else {
        setSubmitError(result.error || "Failed to add safe area");
      }
    } catch (err) {
      setSubmitError("Server error");
    } finally {
      setSubmitLoading(false);
    }
  };

  // Inline styles
  const containerStyle: React.CSSProperties = {
    fontFamily: "Arial, sans-serif",
    background: "#f0f4f8",
    minHeight: "100vh",
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
    padding: "20px",
  };

  const cardStyle: React.CSSProperties = {
    background: "white",
    padding: "30px",
    borderRadius: "12px",
    boxShadow: "0 2px 10px rgba(0,0,0,0.1)",
    width: "100%",
    maxWidth: "500px",
  };

  const inputStyle: React.CSSProperties = {
    width: "100%",
    padding: "10px",
    marginBottom: "15px",
    borderRadius: "6px",
    border: "1px solid #d1d5db",
    fontSize: "14px",
  };

  const buttonStyle: React.CSSProperties = {
    padding: "12px 20px",
    background: "#4f46e5",
    color: "white",
    fontWeight: "bold",
    borderRadius: "6px",
    border: "none",
    cursor: submitLoading ? "not-allowed" : "pointer",
    width: "100%",
  };

  return (
    <div style={containerStyle}>
      <div style={cardStyle}>
        <h2
          style={{ fontSize: "24px", marginBottom: "20px", color: "#1f2937" }}
        >
          Add New Safe Area
        </h2>
        <form onSubmit={handleSubmit}>
          <input
            style={inputStyle}
            type="text"
            name="area"
            placeholder="Area"
            value={formData.area}
            onChange={handleChange}
            required
          />
          <input
            style={inputStyle}
            type="text"
            name="safe_area"
            placeholder="Safe Area"
            value={formData.safe_area}
            onChange={handleChange}
            required
          />
          <input
            style={inputStyle}
            type="text"
            name="longitude"
            placeholder="Longitude"
            value={formData.longitude}
            onChange={handleChange}
            required
          />
          <input
            style={inputStyle}
            type="text"
            name="latitude"
            placeholder="Latitude"
            value={formData.latitude}
            onChange={handleChange}
            required
          />
          <input
            style={inputStyle}
            type="number"
            name="capacity"
            placeholder="Capacity"
            value={formData.capacity}
            onChange={handleChange}
            required
          />
          <input
            style={inputStyle}
            type="number"
            step="0.1"
            name="priority"
            placeholder="Priority"
            value={formData.priority}
            onChange={handleChange}
            required
          />
          {submitSuccess && (
            <p style={{ color: "green", marginBottom: "10px" }}>
              {submitSuccess}
            </p>
          )}
          {submitError && (
            <p style={{ color: "red", marginBottom: "10px" }}>{submitError}</p>
          )}
          <button type="submit" style={buttonStyle} disabled={submitLoading}>
            {submitLoading ? "Submitting..." : "Submit"}
          </button>
        </form>
      </div>
    </div>
  );
};

export default AddSafeArea;
