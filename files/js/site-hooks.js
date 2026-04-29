(function () {
  function loadScript(src, callback) {
    var existing = document.querySelector('script[src="' + src + '"]');
    if (existing) {
      if (callback) {
        if (existing.dataset.loaded === "true") {
          callback();
        } else {
          existing.addEventListener("load", callback, { once: true });
        }
      }
      return;
    }

    var script = document.createElement("script");
    script.src = src;
    script.async = true;
    script.addEventListener("load", function () {
      script.dataset.loaded = "true";
      if (callback) {
        callback();
      }
    });
    document.head.appendChild(script);
  }

  function loadStyle(href) {
    if (document.querySelector('link[href="' + href + '"]')) {
      return;
    }
    var link = document.createElement("link");
    link.rel = "stylesheet";
    link.href = href;
    document.head.appendChild(link);
  }

  function embedWolframNotebooks() {
    var embeds = document.querySelectorAll(".wl-embed[data-wl-id]");
    if (!embeds.length) {
      return;
    }

    function runEmbed() {
      if (!window.WolframNotebookEmbedder) {
        return;
      }

      embeds.forEach(function (node) {
        if (node.dataset.embedded === "true") {
          return;
        }
        var objectId = node.dataset.wlId;
        if (!objectId) {
          return;
        }
        var maxHeight = node.dataset.maxHeight ? parseInt(node.dataset.maxHeight, 10) : Infinity;
        var url = "https://www.wolframcloud.com/obj/" + objectId;
        window.WolframNotebookEmbedder.embed(url, node, {
          allowInteract: true,
          width: null,
          maxHeight: maxHeight,
          showBorder: false,
          useShadowDOM: true,
        });
        node.dataset.embedded = "true";
      });
    }

    if (window.WolframNotebookEmbedder) {
      runEmbed();
      return;
    }

    loadScript(
      "https://unpkg.com/wolfram-notebook-embedder@0.3/dist/wolfram-notebook-embedder.min.js",
      runEmbed
    );
  }

  function initResourcesTable() {
    var table = document.getElementById("resources-table");
    if (!table) {
      return;
    }

    loadStyle("https://cdn.datatables.net/1.13.6/css/jquery.dataTables.min.css");

    function runDataTable() {
      if (!window.jQuery || !window.jQuery.fn || !window.jQuery.fn.DataTable) {
        return;
      }

      if (window.jQuery.fn.DataTable.isDataTable("#resources-table")) {
        return;
      }

      window.jQuery("#resources-table").DataTable({
        responsive: true,
        pageLength: 10,
        order: [[0, "asc"], [1, "asc"], [2, "asc"]],
        orderMulti: true,
        language: { search: "Filter:" },
      });
    }

    loadScript("https://code.jquery.com/jquery-3.6.0.min.js", function () {
      loadScript("https://cdn.datatables.net/1.13.6/js/jquery.dataTables.min.js", runDataTable);
    });
  }

  function initPhotoLightbox() {
    var anchors = Array.prototype.slice.call(document.querySelectorAll(".photo-grid a.lightbox"));
    if (!anchors.length || window.__photoLightboxInitialized) {
      return;
    }

    var modal = document.createElement("div");
    modal.className = "photo-lightbox-modal";
    modal.innerHTML =
      '<button class="photo-lightbox-close" aria-label="Close gallery">&times;</button>' +
      '<button class="photo-lightbox-nav prev" aria-label="Previous image">&#10094;</button>' +
      '<img class="photo-lightbox-image" alt="Expanded photo">' +
      '<button class="photo-lightbox-nav next" aria-label="Next image">&#10095;</button>';
    document.body.appendChild(modal);

    var image = modal.querySelector(".photo-lightbox-image");
    var closeButton = modal.querySelector(".photo-lightbox-close");
    var prevButton = modal.querySelector(".photo-lightbox-nav.prev");
    var nextButton = modal.querySelector(".photo-lightbox-nav.next");
    var currentIndex = 0;

    function openAt(index) {
      currentIndex = (index + anchors.length) % anchors.length;
      var anchor = anchors[currentIndex];
      image.src = anchor.getAttribute("href");
      image.alt = anchor.querySelector("img") ? anchor.querySelector("img").alt : "Expanded photo";
      modal.classList.add("is-open");
      document.body.classList.add("photo-lightbox-open");
    }

    function closeModal() {
      modal.classList.remove("is-open");
      document.body.classList.remove("photo-lightbox-open");
    }

    anchors.forEach(function (anchor, index) {
      anchor.addEventListener("click", function (event) {
        event.preventDefault();
        openAt(index);
      });
    });

    closeButton.addEventListener("click", closeModal);
    prevButton.addEventListener("click", function (event) {
      event.stopPropagation();
      openAt(currentIndex - 1);
    });
    nextButton.addEventListener("click", function (event) {
      event.stopPropagation();
      openAt(currentIndex + 1);
    });

    modal.addEventListener("click", function (event) {
      if (event.target === modal) {
        closeModal();
      }
    });

    document.addEventListener("keydown", function (event) {
      if (!modal.classList.contains("is-open")) {
        return;
      }
      if (event.key === "Escape") {
        closeModal();
      } else if (event.key === "ArrowLeft") {
        openAt(currentIndex - 1);
      } else if (event.key === "ArrowRight") {
        openAt(currentIndex + 1);
      }
    });

    window.__photoLightboxInitialized = true;
  }

  function initBlogPostNav() {
    var postPathMatch = window.location.pathname.match(/\/pages\/Math\/blog\/posts\/([^/]+)\/(?:index\.html)?$/);
    if (!postPathMatch || document.querySelector(".post-nav")) {
      return;
    }

    var sitePrefix = window.location.pathname.split("/pages/Math/blog/posts/")[0];
    var posts = [
      {
        slug: "2026-02-26-repeated-roots",
        title: "Repeated Roots in ODEs",
        href: sitePrefix + "/pages/Math/blog/posts/2026-02-26-repeated-roots/"
      },
      {
        slug: "2025-12-25-square-roots",
        title: "Square Roots and Where to Find Them",
        href: sitePrefix + "/pages/Math/blog/posts/2025-12-25-square-roots/"
      }
    ];

    var currentSlug = postPathMatch[1];
    var index = posts.findIndex(function (post) {
      return post.slug === currentSlug;
    });
    if (index === -1) {
      return;
    }

    var nav = document.createElement("nav");
    nav.className = "post-nav";
    nav.setAttribute("aria-label", "Post navigation");

    var newer = posts[index - 1];
    var older = posts[index + 1];

    if (newer) {
      var newerLink = document.createElement("a");
      newerLink.className = "post-nav-link post-nav-next";
      newerLink.href = newer.href;
      newerLink.innerHTML = '<span>Newer</span><strong>' + newer.title + '</strong>';
      nav.appendChild(newerLink);
    }

    if (older) {
      var olderLink = document.createElement("a");
      olderLink.className = "post-nav-link post-nav-prev";
      olderLink.href = older.href;
      olderLink.innerHTML = '<span>Older</span><strong>' + older.title + '</strong>';
      nav.appendChild(olderLink);
    }

    var main = document.getElementById("quarto-document-content");
    if (main && nav.children.length) {
      main.appendChild(nav);
    }
  }

  function initBlogCategoryLinks() {
    var postPathMatch = window.location.pathname.match(/\/pages\/Math\/blog\/posts\/([^/]+)\/(?:index\.html)?$/);
    if (!postPathMatch) {
      return;
    }

    var sitePrefix = window.location.pathname.split("/pages/Math/blog/posts/")[0];
    var blogHref = sitePrefix + "/pages/Math/blog/blog.html";
    var categories = document.querySelectorAll(".quarto-title .quarto-category");

    categories.forEach(function (category) {
      if (category.querySelector("a")) {
        return;
      }

      var label = category.textContent.trim();
      if (!label) {
        return;
      }

      var link = document.createElement("a");
      link.href = blogHref + "#category=" + encodeURIComponent(label);
      link.textContent = label;
      category.textContent = "";
      category.appendChild(link);
    });
  }

  function initHomepageRecentPostBadges() {
    var listing = document.getElementById("listing-recent-posts");
    if (!listing) {
      return;
    }

    var maxBadges = 3;
    var items = listing.querySelectorAll(".g-col-1[data-categories]");
    items.forEach(function (item) {
      var body = item.querySelector(".card-body");
      var title = item.querySelector(".listing-title");
      if (!body || !title || body.querySelector(".recent-post-badges")) {
        return;
      }

      var rawCategories = item.getAttribute("data-categories") || "";
      var categories = [];
      try {
        categories = decodeURIComponent(window.atob(rawCategories)).split(",");
      } catch (error) {
        categories = [];
      }

      var normalized = categories
        .map(function (category) {
          return category.trim();
        })
        .filter(Boolean)
        .slice(0, maxBadges);

      if (!normalized.length) {
        return;
      }

      var badges = document.createElement("div");
      badges.className = "recent-post-badges";
      normalized.forEach(function (category) {
        var badge = document.createElement("span");
        badge.className = "recent-post-badge";
        badge.textContent = category.toUpperCase();
        badges.appendChild(badge);
      });

      body.insertBefore(badges, title);
    });
  }

  document.addEventListener("DOMContentLoaded", function () {
    embedWolframNotebooks();
    initResourcesTable();
    initPhotoLightbox();
    initBlogPostNav();
    initBlogCategoryLinks();
    initHomepageRecentPostBadges();
  });
})();
