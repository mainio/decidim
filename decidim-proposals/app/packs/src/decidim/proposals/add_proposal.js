import attachGeocoding from "src/decidim/geocoding/attach_input"

$(() => {
  const $checkbox = $("input:checkbox[name$='[has_address]']");
  const $addressInput = $("#address_input");
  const $addressInputField = $("input", $addressInput);

  if ($checkbox.length > 0) {
    const toggleInput = () => {
      if ($checkbox[0].checked) {
        $addressInput.show();
        $addressInputField.prop("disabled", false);
      } else {
        $addressInput.hide();
        $addressInputField.prop("disabled", true);
      }
    }
    toggleInput();
    $checkbox.on("change", toggleInput);
  }

  if ($addressInput.length > 0) {
    attachGeocoding($addressInputField);
  }
});
