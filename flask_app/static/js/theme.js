// Theme: prefers-color-scheme default, user override via localStorage.
// Applies theme by setting: <html data-theme="light|dark">

(function () {
  const STORAGE_KEY = "jit_theme"; // "light" | "dark"

  function getPreferredTheme() {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      if (stored === "light" || stored === "dark") return stored;
    } catch (e) {
      // ignore
    }

    const prefersDark =
      window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches;
    return prefersDark ? "dark" : "light";
  }

  function applyTheme(theme) {
    document.documentElement.setAttribute("data-theme", theme);
  }

  function setTheme(theme) {
    applyTheme(theme);
    try {
      localStorage.setItem(STORAGE_KEY, theme);
    } catch (e) {
      // ignore
    }
  }

  // Apply immediately (in case inline script wasn't present)
  applyTheme(getPreferredTheme());

  window.JITTheme = {
    get: () => document.documentElement.getAttribute("data-theme") || "light",
    set: setTheme,
    toggle: () => setTheme(window.JITTheme.get() === "dark" ? "light" : "dark"),
  };

  document.addEventListener("DOMContentLoaded", function () {
    const toggle = document.getElementById("theme-toggle");
    if (!toggle) return;

    const label = toggle.querySelector("[data-theme-label]");
    const syncLabel = () => {
      if (!label) return;
      label.textContent = window.JITTheme.get() === "dark" ? "Dark" : "Light";
    };

    syncLabel();
    toggle.addEventListener("click", function () {
      window.JITTheme.toggle();
      syncLabel();
    });
  });
})();

