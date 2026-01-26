// -----------------------------------------------------------------------------
// Configuration
// -----------------------------------------------------------------------------
// Base URL for backend API (Flask service behind ALB)
// In production, ensure this domain has a valid ACM certificate.
// For local testing, you can temporarily use http://localhost:5000/db
const API_BASE_URL = "https://api.zachmaestas-capstone.com/db";

// -----------------------------------------------------------------------------
// DOM Elements
// -----------------------------------------------------------------------------
const list = document.getElementById("item-list");
const form = document.getElementById("item-form");
const nameInput = document.getElementById("item-name");

// -----------------------------------------------------------------------------
// Fetch and Render Items
// -----------------------------------------------------------------------------
async function fetchItems() {
  list.innerHTML = "<li>Loading...</li>";
  try {
    const response = await fetch(`${API_BASE_URL}/items`);
    if (!response.ok) throw new Error(`Server responded with ${response.status}`);
    const data = await response.json();

    if (!data.items || data.items.length === 0) {
      list.innerHTML = "<li>No items found.</li>";
      return;
    }

    // Clear list and render items
    list.innerHTML = "";
    data.items.forEach((item) => {
      const li = document.createElement("li");
      li.textContent = `${item.id}: ${item.name}`;

      const delBtn = document.createElement("button");
      delBtn.textContent = "Delete";
      delBtn.className = "delete-btn";
      delBtn.onclick = () => deleteItem(item.id);

      li.appendChild(delBtn);
      list.appendChild(li);
    });
  } catch (err) {
    console.error("Error loading items:", err);
    list.innerHTML = `<li class="error">Failed to load items. Please try again.</li>`;
  }
}

// -----------------------------------------------------------------------------
// Add New Item
// -----------------------------------------------------------------------------
form.addEventListener("submit", async (e) => {
  e.preventDefault();
  const name = nameInput.value.trim();
  if (!name) return alert("Please enter a name.");

  // Disable button to prevent double submission
  const submitBtn = form.querySelector("button[type='submit']");
  submitBtn.disabled = true;

  try {
    const response = await fetch(`${API_BASE_URL}/items`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name }),
    });

    if (!response.ok) {
      const errData = await response.json();
      throw new Error(errData.error || `HTTP ${response.status}`);
    }

    nameInput.value = "";
    fetchItems();
  } catch (err) {
    console.error("Add item failed:", err);
    alert("Failed to add item. Please try again.");
  } finally {
    submitBtn.disabled = false;
  }
});

// -----------------------------------------------------------------------------
// Delete Item
// -----------------------------------------------------------------------------
async function deleteItem(id) {
  if (!confirm("Delete this item?")) return;

  try {
    const response = await fetch(`${API_BASE_URL}/items/${id}`, { method: "DELETE" });
    if (!response.ok) throw new Error(`Failed with ${response.status}`);
    fetchItems();
  } catch (err) {
    console.error("Delete failed:", err);
    alert("Failed to delete item. Please try again.");
  }
}

// -----------------------------------------------------------------------------
// Initialize
// -----------------------------------------------------------------------------
fetchItems();
