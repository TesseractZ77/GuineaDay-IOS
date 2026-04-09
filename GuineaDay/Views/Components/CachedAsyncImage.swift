import SwiftUI

/// A drop-in replacement for AsyncImage that caches downloads in memory.
/// On first load it fetches from the network; on all subsequent views it
/// returns instantly from NSCache — no more 3-5 second waits.
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var uiImage: UIImage? = nil
    @State private var isLoading = false

    init(url: URL?,
         @ViewBuilder content: @escaping (Image) -> Content,
         @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
        // Pre-populate from cache synchronously so there is zero flash on revisit
        if let url, let cached = ImageCacheService.shared.image(for: url.absoluteString) {
            _uiImage = State(initialValue: cached)
        }
    }


    var body: some View {
        Group {
            if let uiImage {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
                    .task { await load() }
            }
        }
        // When the URL changes (e.g. profile photo updated), @State is NOT reset
        // automatically by SwiftUI — we must do it manually.
        .onChange(of: url) { _, newURL in
            uiImage    = nil
            isLoading  = false
            guard let newURL else { return }
            // Synchronous cache hit: saveProfile() already stored the image here
            if let cached = ImageCacheService.shared.image(for: newURL.absoluteString) {
                uiImage = cached
            }
            // Cache miss → placeholder's .task will call load() and download it
        }
    }

    private func load() async {
        guard !isLoading, let url else { return }
        let urlStr = url.absoluteString

        // 1. Cache hit — instant
        if let cached = ImageCacheService.shared.image(for: urlStr) {
            uiImage = cached
            return
        }

        // 2. Cache miss — download then cache
        isLoading = true
        if let (data, _) = try? await URLSession.shared.data(from: url),
           let img = UIImage(data: data) {
            ImageCacheService.shared.store(img, for: urlStr)
            uiImage = img
        }
        isLoading = false
    }
}
