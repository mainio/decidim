/* eslint-disable require-jsdoc */

import Quill, { createServerUploader } from "dippen";

// import lineBreakButtonHandler from "src/decidim/editor/linebreak_module";
// import "src/decidim/editor/clipboard_override";
// import "src/decidim/vendor/image-resize.min";
// import "src/decidim/vendor/image-upload.min";

const quillFormats = [
  "bold",
  "italic",
  "link",
  "underline",
  "header",
  "list",
  "break",
  "soft-break",
  "code",
  "blockquote",
  "indent"
];

window.Quill = Quill;

export default function createQuillEditor(container) {
  const toolbar = container.dataset.toolbar;
  const disabled = container.dataset.disabled === "true";

  const allowedEmptyContentSelector = "iframe";
  let quillToolbar = [
    ["bold", "italic", "underline", "soft-break"],
    [{ list: "ordered" }, { list: "bullet" }],
    ["link", "clean"],
    ["code", "blockquote"],
    [{ indent: "-1" }, { indent: "+1" }]
  ];

  let addImage = false;
  let addVideo = false;

  /**
   * - basic = only basic controls without titles
   * - content = basic + headings
   * - full = basic + headings + image + video
   */
  if (toolbar === "content") {
    quillToolbar = [[{ header: [2, 3, 4, 5, 6, false] }], ...quillToolbar];
  } else if (toolbar === "full") {
    addImage = true;
    addVideo = true;
    quillToolbar = [
      [{ header: [2, 3, 4, 5, 6, false] }],
      ...quillToolbar,
      ["video"],
      ["image"]
    ];
  }

  let modules = {
    toolbar: {
      container: quillToolbar
    }
  };
  const $input = $(container).siblings('input[type="hidden"]');
  container.innerHTML = $input.val() || "";

  if (addVideo) {
    quillFormats.push("video");
  }

  if (addImage) {
    quillFormats.push("image");

    const uploadUrl = container.dataset.uploadImagesPath;
    const token = document.querySelector("meta[name='csrf-token']").getAttribute("content");
    const imageUploader = createServerUploader(uploadUrl, {
      headers: { "X-CSRF-Token": token }
    });

    modules.imageResize = {
      modules: ["Resize", "DisplaySize", "Keyboard"]
    };
    modules.imageAlt = true;
    modules.uploader = {
      async uploadHandler(file) {
        const response = await imageUploader(file);
        return response.url;
      }
    }

    const help = document.createElement("p");
    help.classList.add("help-text");
    help.style.marginTop = "-1.5rem";
    help.innerText = container.dataset.dragAndDropHelpText;
    container.after(help);
  }
  const quill = new Quill(container, {
    readOnly: disabled,
    modules: modules,
    formats: quillFormats,
    theme: "snow"
  });

  quill.on("text-change", () => {
    const text = quill.getText();

    // Triggers CustomEvent with the cursor position
    // It is required in input_mentions.js
    let event = new CustomEvent("quill-position", {
      detail: quill.getSelection()
    });
    container.dispatchEvent(event);

    if (
      (text === "\n" || text === "\n\n") &&
      quill.root.querySelectorAll(allowedEmptyContentSelector).length === 0
    ) {
      $input.val("");
    } else {
      const emptyParagraph = "<p><br></p>";
      const cleanHTML = quill.root.innerHTML.replace(
        new RegExp(`^${emptyParagraph}|${emptyParagraph}$`, "g"),
        ""
      );
      $input.val(cleanHTML);
    }
  });

  // Keep this event for backwards compatibility. No longer internally needed
  // as this was previously used by the linebreak module.
  quill.emitter.emit("editor-ready");

  return quill;
}
