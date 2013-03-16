//@ sourceMappingURL=util.map
// Generated by CoffeeScript 1.6.1
(function() {
  var Point, Rect, vector,
    __slice = [].slice;

  if (console !== void 0 && console.assert !== void 0) {
    window.assert = console.assert.bind(console);
  } else {
    window.assert = function(exp, message) {
      if (!exp) {
        throw message;
      }
    };
  }

  Point = (function() {

    function Point() {}

    Point.distance = function(pt1, pt2) {
      var dx, dy;
      dx = pt2[0] - pt1[0];
      dy = pt2[1] - pt1[1];
      return Math.sqrt(dx * dx + dy * dy);
    };

    return Point;

  })();

  assert(Point.distance([0, 0], [1, 0]) === 1);

  assert(Point.distance([0, 0], [3, 4]) === 5);

  window.Point = Point;

  Rect = (function() {

    function Rect(x1, y1, x2, y2) {
      this.x1 = x1;
      this.y1 = y1;
      this.x2 = x2;
      this.y2 = y2;
    }

    Rect.fromWH = function(x, y, w, h) {
      return new Rect(x, y, x + w, y + h);
    };

    Rect.fromRoom = function(room) {
      return new Rect(room.getLeft(), room.getTop(), room.getRight(), room.getBottom());
    };

    Rect.prototype.center = function() {
      return [this.x1 + (this.x2 - this.x1) / 2, this.y1 + (this.y2 - this.y1) / 2];
    };

    Rect.prototype.containsXY = function(x, y) {
      return x >= this.x1 && x < this.x2 && y >= this.y1 && y < this.y2;
    };

    Rect.prototype.area = function() {
      return Math.abs(this.x2 - this.x1) * Math.abs(this.y2 - this.y1);
    };

    Rect.prototype.width = function() {
      return Math.abs(this.x2 - this.x1) + 1;
    };

    Rect.prototype.height = function() {
      return Math.abs(this.y2 - this.y1) + 1;
    };

    return Rect;

  })();

  window.Rect = Rect;

  window.isRGB = function(o) {
    return o.length === 3 && typeof o[0] === 'number' && typeof o[1] === 'number' && typeof o[2] === 'number';
  };

  window.clampColor = function(c) {
    var i, _i, _results;
    _results = [];
    for (i = _i = 0; _i <= 2; i = ++_i) {
      _results.push(ROT.Color._clamp(c[i]));
    }
    return _results;
  };

  window.queryString = function(key) {
    var match;
    key = key.replace(/[*+?^$.\[\]{}()|\\\/]/g, "\\$&");
    match = location.search.match(new RegExp("[?&]" + key + "=([^&]+)(&|$)"));
    return match && decodeURIComponent(match[1].replace(/\+/g, " "));
  };

  window.queryInt = function(key) {
    var n, s;
    s = queryString(key);
    if (s != null) {
      n = parseInt(s, 10);
      if (!isNaN(n)) {
        return n;
      }
    }
  };

  window.htmlEntities = function(str) {
    return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  };

  vector = {
    cardinals: {
      up: [0, -1],
      down: [0, 1],
      right: [1, 0],
      left: [-1, 0]
    },
    add: function(a, b) {
      return [a[0] + b[0], a[1] + b[1]];
    },
    subtract: function(a, b) {
      return [a[0] - b[0], a[1] - b[1]];
    },
    length: function(a) {
      return Math.sqrt(a[0] * a[0] + a[1] * a[1]);
    },
    length2: function(a) {
      return a[0] * a[0] + a[1] * a[1];
    },
    projectOn: function(self, v) {
      var s;
      s = (self[0] * v[0] + self[1] * v[1]) / (v[0] * v[0] + v[1] * v[1]);
      return [s * v[0], s * v[1]];
    },
    closestCardinal: function(a) {
      var cardinalVector, longestVec, maxDistance, name, projected, projectedLength, _ref;
      maxDistance = 0;
      _ref = vector.cardinals;
      for (name in _ref) {
        cardinalVector = _ref[name];
        projected = vector.projectOn(a, cardinalVector);
        projectedLength = vector.length2(projected);
        if (projectedLength > maxDistance) {
          longestVec = projected;
          maxDistance = projectedLength;
        }
      }
      return vector.normalized(longestVec);
    },
    normalized: function(v) {
      var l;
      l = vector.length(v);
      return [v[0] / l, v[1] / l];
    }
  };

  window.vector = vector;

  window.extend = function(obj, mixin) {
    var name, value;
    for (name in mixin) {
      value = mixin[name];
      obj[name] = value;
    }
    return obj;
  };

  window.funcOrString = function() {
    var args, f;
    f = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    if (typeof f === 'string') {
      return f;
    } else {
      return f.apply(null, args);
    }
  };

  window.statusColor = function(color, text) {
    return '<span style="color: %s;">%s</span>'.format(color, text);
  };

  window.range = function(x1, x2, grow) {
    var c1, c2;
    c1 = Math.min(x1) - grow;
    c2 = Math.max(x2) + grow;
    return [c1, c2];
  };

}).call(this);