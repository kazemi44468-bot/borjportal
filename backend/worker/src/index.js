export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname === "/health") {
      return Response.json({ ok: true, service: "borjportal-api" });
    }
    return Response.json({ error: "not_found" }, { status: 404 });
  }
};
