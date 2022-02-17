/* global checkUserLoggedIn */

function removeExistingCSRF() {
  var csrfTokenMeta = document.querySelector("meta[name='csrf-token']");
  var csrfParamMeta = document.querySelector("meta[name='csrf-param']");
  if (csrfTokenMeta && csrfParamMeta) {
    csrfTokenMeta.parentNode.removeChild(csrfTokenMeta);
    csrfParamMeta.parentNode.removeChild(csrfParamMeta);
  }
}

/* TODO: prefer fetch() to XMLHttpRequest */
function fetchBaseData() {
  var xmlhttp;
  xmlhttp = new XMLHttpRequest();
  xmlhttp.onreadystatechange = () => {
    if (xmlhttp.readyState === XMLHttpRequest.DONE) {
      // Assigning CSRF
      var json = JSON.parse(xmlhttp.responseText);
      if (json.token) {
        removeExistingCSRF();
      }
      var newCsrfParamMeta = document.createElement('meta');
      newCsrfParamMeta.name = 'csrf-param';
      newCsrfParamMeta.content = json.param;
      document.head.appendChild(newCsrfParamMeta);
      var newCsrfTokenMeta = document.createElement('meta');
      newCsrfTokenMeta.name = 'csrf-token';
      newCsrfTokenMeta.content = json.token;
      document.head.appendChild(newCsrfTokenMeta);
      document.body.dataset.loaded = 'true';

      // Assigning Broadcast
      if (json.broadcast) {
        document.body.dataset.broadcast = json.broadcast;
      }

      // Assigning User
      if (checkUserLoggedIn()) {
        document.body.dataset.user = json.user;
        document.body.dataset.creator = json.creator;
        browserStoreCache('set', json.user);

        setTimeout(() => {
          if (typeof ga === 'function') {
            ga('set', 'userId', JSON.parse(json.user).id);
          }
        }, 400);
      } else {
        // Ensure user data is not exposed if no one is logged in
        delete document.body.dataset.user;
        delete document.body.dataset.creator;
        browserStoreCache('remove');
      }
    }
  };

  xmlhttp.open('GET', '/async_info/base_data', true);
  xmlhttp.send();
}

function initializeBodyData() {
  fetchBaseData();
}
