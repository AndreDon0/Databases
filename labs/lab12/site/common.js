/** Shared helpers for warehouse UI. */

export function $(sel, root = document) {
  return root.querySelector(sel);
}

export function showToast(message, type = "ok") {
  const el = document.getElementById("toast");
  if (!el) return;
  el.textContent = message;
  el.hidden = false;
  el.className = `toast ${type}`;
  clearTimeout(showToast._t);
  showToast._t = setTimeout(() => {
    el.hidden = true;
  }, 4200);
}

export async function parseError(res) {
  try {
    const j = await res.json();
    if (j && typeof j.detail === "string") return j.detail;
    if (Array.isArray(j.detail)) return j.detail.map((d) => d.msg || d).join("; ");
  } catch {
    /* ignore */
  }
  return res.statusText || `HTTP ${res.status}`;
}

export function encPathSegment(s) {
  return encodeURIComponent(s);
}

export function escapeHtml(s) {
  return String(s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

export function escapeAttr(s) {
  return escapeHtml(s).replace(/'/g, "&#39;");
}

export function bindSortArrows(container, onSort) {
  container.querySelectorAll(".sort-arrow").forEach((btn) => {
    btn.addEventListener("click", (e) => {
      e.preventDefault();
      const field = btn.getAttribute("data-sort");
      const order = btn.getAttribute("data-order");
      if (field && order) onSort(field, order);
    });
  });
}
