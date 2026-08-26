// Cloudflare Pages advanced mode.
//
// 1. pressenter.xyz is the only hostname that serves the blog. Anything else
//    (pressenter.pages.dev, preview deployments, www) is 301'd to the
//    canonical apex with path and query preserved.
// 2. "/" is a server-side 301 to "/blog/", replacing the client-side
//    JavaScript bounce that Zola's `redirect_to` generates.
const CANONICAL = "pressenter.xyz";
const LOCAL = ["localhost", "127.0.0.1", "0.0.0.0", "[::1]"];

export default {
	async fetch(request, env) {
		const url = new URL(request.url);

		if (url.hostname !== CANONICAL && !LOCAL.includes(url.hostname)) {
			url.hostname = CANONICAL;
			url.protocol = "https:";
			url.port = "";
			return Response.redirect(url.toString(), 301);
		}

		if (url.pathname === "/") {
			url.pathname = "/blog/";
			return Response.redirect(url.toString(), 301);
		}

		return env.ASSETS.fetch(request);
	},
};
