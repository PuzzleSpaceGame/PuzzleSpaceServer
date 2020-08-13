// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
// import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"
import {Socket} from "phoenix"
import drawing_api from "./puzzle_rendering_engine"
import interaction_handler from "./puzzle_interaction_engine"
const event = new CustomEvent("imports_complete", {detail: {socket:Socket,dpi:drawing_api,ih:interaction_handler}})
document.dispatchEvent(event)
