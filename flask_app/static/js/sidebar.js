// Optional: sidebar collapse toggle (desktop-only).
// Applies state by setting: <html data-sidebar="collapsed|expanded">

(function () {
  const STORAGE_KEY = "jit_sidebar";

  function getState() {
    try {
      const s = localStorage.getItem(STORAGE_KEY);
      if (s === "collapsed" || s === "expanded") return s;
    } catch (e) {
      // ignore
    }
    return "expanded";
  }

  function apply(state) {
    document.documentElement.setAttribute("data-sidebar", state);
  }

  function setState(state) {
    apply(state);
    try {
      localStorage.setItem(STORAGE_KEY, state);
    } catch (e) {
      // ignore
    }
  }

  apply(getState());

  document.addEventListener("DOMContentLoaded", function () {
    const btn = document.getElementById("sidebar-toggle");
    if (!btn) return;

    btn.addEventListener("click", function () {
      const current =
        document.documentElement.getAttribute("data-sidebar") || "expanded";
      setState(current === "collapsed" ? "expanded" : "collapsed");
    });
  });
})();

