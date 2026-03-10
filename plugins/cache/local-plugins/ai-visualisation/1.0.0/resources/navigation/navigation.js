/**
 * Navigation.js - IntersectionObserver-basierte Navigation für AI-Visualisierungen
 *
 * Funktionalität:
 * - Page Counter: Zeigt aktuelle Section und Gesamtanzahl an
 * - Sidebar Navigation: Markiert aktive Section und ermöglicht smooth scrolling
 * - IntersectionObserver: Erkennt sichtbarste Section mit 30% Viewport-Schwellenwert
 */

class VisualizationNavigation {
  constructor() {
    this.observer = null;
    this.currentIndex = 0;
    this.totalSections = 0;
    this.isScrolling = false;
    this.pageCounterEl = null;
    this.sidebarNavEl = null;
  }

  /**
   * Initialisiert die Navigation
   * - Erkennt Elemente (.page-counter, .sidebar-nav, section)
   * - Setzt IntersectionObserver auf
   */
  init() {
    this.pageCounterEl = document.querySelector('.page-counter');
    this.sidebarNavEl = document.querySelector('.sidebar-nav');

    const sections = document.querySelectorAll('section[id]');
    this.totalSections = sections.length;

    // Graceful Degradation: Wenn keine Sections, nichts tun
    if (this.totalSections === 0) {
      console.warn('Navigation.js: Keine Sections mit ID gefunden');
      return;
    }

    // Page Counter initialisieren
    if (this.pageCounterEl) {
      this.updatePageCounter(0, this.totalSections);
    }

    // Sidebar Navigation initialisieren
    if (this.sidebarNavEl) {
      this.attachClickHandlers();
      this.updateSidebarActive(0);
    }

    // IntersectionObserver starten
    this.setupIntersectionObserver(sections);
  }

  /**
   * Setzt IntersectionObserver auf mit 30% Viewport-Schwellenwert
   */
  setupIntersectionObserver(sections) {
    const options = {
      threshold: 0.3,      // Section mindestens 30% sichtbar
      rootMargin: '0px'
    };

    this.observer = new IntersectionObserver((entries) => {
      // Während des Scrollens keine Updates (verhindert Flackern)
      if (this.isScrolling) return;

      // Finde die sichtbarste Section (highest intersection ratio)
      let mostVisibleEntry = entries[0];
      entries.forEach((entry) => {
        if (entry.intersectionRatio > mostVisibleEntry.intersectionRatio) {
          mostVisibleEntry = entry;
        }
      });

      // Wenn sichtbar und intersection ratio > 0.3
      if (mostVisibleEntry.isIntersecting) {
        const index = Array.from(sections).indexOf(mostVisibleEntry.target);
        this.updateNavigation(index);
      }
    }, options);

    // Beobachte alle Sections
    sections.forEach((section) => {
      this.observer.observe(section);
    });
  }

  /**
   * Aktualisiert Navigation (Counter + Sidebar)
   */
  updateNavigation(index) {
    this.currentIndex = index;

    if (this.pageCounterEl) {
      this.updatePageCounter(index, this.totalSections);
    }

    if (this.sidebarNavEl) {
      this.updateSidebarActive(index);
    }
  }

  /**
   * Aktualisiert Page Counter
   * - Zeigt aktuelle Section (1-basiert) und Gesamtanzahl
   * - Versteckt Counter wenn nur 1 Section
   */
  updatePageCounter(currentIndex, totalSections) {
    const currentSpan = this.pageCounterEl.querySelector('.current');

    if (!currentSpan) {
      console.warn('Navigation.js: .page-counter .current nicht gefunden');
      return;
    }

    // 1-basierte Anzeige (currentIndex 0 → display 1)
    currentSpan.textContent = currentIndex + 1;

    // Verstecke Counter wenn nur 1 Section
    if (totalSections === 1) {
      this.pageCounterEl.classList.add('hidden');
    } else {
      this.pageCounterEl.classList.remove('hidden');
    }
  }

  /**
   * Aktualisiert Sidebar Navigation Highlighting
   * - Entfernt aria-current="true" vom alten Item
   * - Setzt aria-current="true" auf neuem Item
   * - Scrollt Sidebar so dass aktives Item sichtbar ist
   */
  updateSidebarActive(currentIndex) {
    const links = this.sidebarNavEl.querySelectorAll('a');

    if (currentIndex >= links.length) {
      console.warn(`Navigation.js: Index ${currentIndex} außerhalb der Links-Range`);
      return;
    }

    // Entferne aria-current von allen Links
    links.forEach((link) => {
      link.removeAttribute('aria-current');
    });

    // Setze aria-current auf aktuellem Link
    const activeLink = links[currentIndex];
    activeLink.setAttribute('aria-current', 'true');

    // Scrolle Sidebar so dass aktives Item sichtbar ist
    this.scrollSidebarToLink(activeLink);
  }

  /**
   * Scrollt Sidebar so dass aktives Link-Item sichtbar ist (smooth)
   */
  scrollSidebarToLink(link) {
    const container = this.sidebarNavEl;
    const linkRect = link.getBoundingClientRect();
    const containerRect = container.getBoundingClientRect();

    // Prüfe ob Link sichtbar ist
    const isAbove = linkRect.top < containerRect.top;
    const isBelow = linkRect.bottom > containerRect.bottom;

    if (isAbove || isBelow) {
      link.scrollIntoView({
        behavior: 'smooth',
        block: 'nearest',
        inline: 'nearest'
      });
    }
  }

  /**
   * Hängt Click Handler an Sidebar Links an
   * - Ermöglicht Smooth Scroll zur entsprechenden Section
   * - Pausiert IntersectionObserver während des Scrolls (verhindert Flackern)
   */
  attachClickHandlers() {
    const links = this.sidebarNavEl.querySelectorAll('a[href^="#"]');

    links.forEach((link) => {
      link.addEventListener('click', (e) => {
        e.preventDefault();

        const targetId = link.getAttribute('href').substring(1);
        const targetSection = document.getElementById(targetId);

        if (!targetSection) {
          console.warn(`Navigation.js: Section mit ID "${targetId}" nicht gefunden`);
          return;
        }

        // Pausiere IntersectionObserver während Scroll
        this.isScrolling = true;

        // Scrolle zur Section
        targetSection.scrollIntoView({
          behavior: 'smooth',
          block: 'start'
        });

        // Finde Index der Target-Section
        const sections = document.querySelectorAll('section[id]');
        const index = Array.from(sections).indexOf(targetSection);

        // Aktualisiere Navigation sofort (ohne auf Observer zu warten)
        this.updateNavigation(index);

        // Aktiviere Observer wieder nach Scroll endet
        // scrollend Event ist nicht zuverlässig, nutze setTimeout
        setTimeout(() => {
          this.isScrolling = false;
        }, 1000); // 1 Sekunde sollte für smooth scroll ausreichend sein
      });
    });
  }

  /**
   * Räumt auf (Observer stoppen)
   */
  destroy() {
    if (this.observer) {
      this.observer.disconnect();
    }
  }
}

/**
 * Initialisiert Navigation beim DOMContentLoaded
 */
function initNavigation() {
  if (document.readyState === 'loading') {
    // DOM wird noch geladen
    document.addEventListener('DOMContentLoaded', () => {
      const nav = new VisualizationNavigation();
      nav.init();

      // Speichere Instanz im Window für ggf. Zugriff
      window.visualizationNav = nav;
    });
  } else {
    // DOM ist bereits geladen
    const nav = new VisualizationNavigation();
    nav.init();
    window.visualizationNav = nav;
  }
}

// Starte Navigation automatisch
initNavigation();
