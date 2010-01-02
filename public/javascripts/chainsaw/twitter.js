Chainsaw.Util.highlightUsers = function(t) {
  return t.replace(/(^|\s)@([_a-z0-9]+)/gi, '$1@<a href="http://twitter.com/$2" target="_blank">$2</a>');
};

Chainsaw.Util.highlightTags = function(t) {
  return t.replace(/(^|\s)#(\S+(\/|\b))/gi, '$1<a href="http://twitter.com/search?q=%23$2" target="_blank">#$2</a>');
};

Chainsaw.Util.twitterize = function(t) {
  return this.highlightTags(this.highlightUsers(this.autolink(t)));
};

Chainsaw.onMessage("twitter", function(d) {
  var container = get("chainsaw-twitter");
  if(!container) return;
  var message   = elem("li", "", {'class': "twitter-message"}),
      name      = d.screen_name,
      avatarURL = d.avatar;
  var avatar     = elem("img", null, {'src': avatarURL, 'alt': h(name)}),
      profileURL = "http://twitter.com/" + name;
  // Create the contact.
  message.appendChild(elem("a", avatar, {'target': '_blank', 'href': profileURL, 'class': 'avatar'}));
  message.appendChild(elem("a", h(name), {'target': '_blank', 'href': profileURL, 'class': 'name'}));
  message.appendChild(elem("span", twitterize(d.dext), {'class': 'message'}));
  // Actually add the message
  prependChild(container, message);
});