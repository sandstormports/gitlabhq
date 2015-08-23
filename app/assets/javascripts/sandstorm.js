
function sandstormGetWebkey(project_path) {

var path_with_ext = project_path + ".git"

var messageListener = function(event) {
  if (event.data.rpcId === "0") {
    if (event.data.error) {
      console.log("ERROR: " + event.data.error);
    } else {
      var el = document.getElementById("webkey-offer");
      el.setAttribute("src", event.data.uri);
    }
  }
};

var username = "any_username";
if (window.crypto) {
  var array = new Uint32Array(8);
  window.crypto.getRandomValues(array);
  username = "";
  for (var ii = 0; ii < array.length; ++ii) {
    username = username + String.fromCharCode(97 + (array[ii] % 26));
  }
}

window.addEventListener("message", messageListener);
var template =
    " echo url=" + window.location.protocol + "//" + username + ":$API_TOKEN@$API_HOST/" + path_with_ext + " |" +
    " git -c credential.helper=store credential approve\n" +
    " git clone -c credential.helper=store " + window.location.protocol + "//" + username + "@$API_HOST/" +
    path_with_ext + " repo_" + username + "_RENAME_ME\n";
window.parent.postMessage({renderTemplate: {rpcId: "0", template: template}}, "*");

}
