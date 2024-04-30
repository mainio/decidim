/**
 * Global (window) variables that are needed across the application.
 *
 * This needs to be loaded at the top of the main entrypoint before any other
 * import for it to work properly.
 *
 * Some globals are needed because external libraries and the frontend-facing
 * dynamic code (i.e. `*.erb.js`) may depend on some global variables being
 * available. This is not ideal but the world is not yet completed as Decidim
 * depends also on external packages.
 */

import jQuery from "jquery";
import Rails from "@rails/ujs"

globalThis.$ = jQuery; // eslint-disable-line id-length
globalThis.jQuery = jQuery;
globalThis.Rails = Rails;
