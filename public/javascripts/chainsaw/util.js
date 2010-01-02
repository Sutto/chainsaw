if(typeof(Chainsaw) != "object") Chainsaw = {};
if(typeof(Chainsaw.Util) != "object") Chainsaw.Util = {};

Chainsaw.Util.h = function(t) {
  return t.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/'/g, "&#39;").replace(/"/g, "&quot;");
};

Chainsaw.Util.autolink = function(text) {
  return text.replace(/(\bhttp:\/\/\S+(\/|\b))/gi, '<a href="$1" target="_blank">$1</a>');
};

Chainsaw.Util.format = function(t) {
  return this.autolink(this.h(t));
};

Chainsaw.Util.elem = function(tag, inner, attributes) {
  var element = document.createElement(tag);
  if(inner) {
    switch(typeof(inner)) {
    case "string":
      element.innerHTML = inner;
      break;
    default:
      element.appendChild(inner);
      break;
    }
  }
  for(var attribute in attributes) {
    var value = attributes[attribute];
    element.setAttribute(attribute, value);
  }
  return element;
};

Chainsaw.Util.get = function(id) {
  return document.getElementById(id);
};

Chainsaw.Util.prependChild = function(parent, element) {
  if(parent.childElementCount < 1) parent.appendChild(element);
  else parent.insertBefore(element, parent.firstChild);
};