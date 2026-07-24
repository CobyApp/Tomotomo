// Language switcher for the Tomotomo legal pages.
// Language priority: ?lang= query param → browser language → Korean.
// The app opens these pages with ?lang=<app locale> so the doc matches the UI.
(function () {
  var supported = ['ko', 'ja', 'en', 'zh'];

  function pickLang() {
    var q = new URLSearchParams(location.search).get('lang');
    if (q && supported.indexOf(q) !== -1) return q;
    var nav = (navigator.language || 'ko').slice(0, 2).toLowerCase();
    return supported.indexOf(nav) !== -1 ? nav : 'ko';
  }

  function apply(lang) {
    document.documentElement.lang = lang;
    var sections = document.querySelectorAll('[data-lang]');
    for (var i = 0; i < sections.length; i++) {
      sections[i].hidden = sections[i].getAttribute('data-lang') !== lang;
    }
    var btns = document.querySelectorAll('.langbtn');
    for (var j = 0; j < btns.length; j++) {
      btns[j].setAttribute(
        'aria-current',
        btns[j].getAttribute('data-set') === lang ? 'true' : 'false'
      );
    }
  }

  document.addEventListener('DOMContentLoaded', function () {
    apply(pickLang());
    var btns = document.querySelectorAll('.langbtn');
    for (var i = 0; i < btns.length; i++) {
      btns[i].addEventListener('click', function (e) {
        var lang = e.currentTarget.getAttribute('data-set');
        apply(lang);
        var u = new URL(location.href);
        u.searchParams.set('lang', lang);
        history.replaceState(null, '', u);
      });
    }
  });
})();
