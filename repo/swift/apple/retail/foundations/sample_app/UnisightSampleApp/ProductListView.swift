import SwiftUI

struct ProductListView: View {
    @State private var products: [Product] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    
    private let categories = ["All", "Electronics", "Clothing", "Home", "Books"]
    
    var filteredProducts: [Product] {
        var filtered = products
        
        if selectedCategory != "All" {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                SearchBar(text: $searchText)
                    .onChange(of: searchText) { oldValue, newValue in
                        TelemetryService.shared.logUserInteraction(
                            .entry,
                            viewName: "ProductList",
                            elementId: "search_bar"
                        )
                    }
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            CategoryChip(
                                title: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                                TelemetryService.shared.logUserInteraction(
                                    .selection,
                                    viewName: "ProductList",
                                    elementId: "category_\(category.lowercased())"
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Product List
                if isLoading {
                    ProgressView("Loading products...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredProducts.isEmpty {
                    EmptyStateView()
                } else {
                    List(filteredProducts) { product in
                        NavigationLink(destination: ProductDetailView(product: product)) {
                            ProductRowView(product: product)
                        }
                        .onTapGesture {
                            TelemetryService.shared.logUserInteraction(
                                .tap,
                                viewName: "ProductList",
                                elementId: "product_\(product.id)"
                            )
                        }
                    }
                }
            }
            .navigationTitle("Products")
            .onAppear {
                TelemetryService.shared.logEvent(
                    name: "product_list_appeared",
                    category: .navigation
                )
                loadProducts()
            }
            .refreshable {
                await refreshProducts()
            }
        }
    }
    
    private func loadProducts() {
        isLoading = true
        TelemetryService.shared.logEvent(
            name: "products_load_started",
            category: .functional
        )
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            products = Product.sampleProducts
            isLoading = false
            
            TelemetryService.shared.logEvent(
                name: "products_loaded",
                category: .functional,
                attributes: [
                    "product_count": products.count,
                    "load_time": 1.0
                ]
            )
        }
    }
    
    private func refreshProducts() async {
        TelemetryService.shared.logUserInteraction(
            .pan,
            viewName: "ProductList"
        )
        
        // Simulate refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        products = Product.sampleProducts.shuffled()
        
        TelemetryService.shared.logEvent(
            name: "products_refreshed",
            category: .functional
        )
    }
}

// MARK: - Supporting Views

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search products...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.horizontal)
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct ProductRowView: View {
    let product: Product
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: product.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(product.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("$\(product.price, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            VStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("\(product.rating, specifier: "%.1f")")
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No products found")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Try adjusting your search or filters")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Product Model

struct Product: Identifiable, Codable {
    let id: String
    let name: String
    let category: String
    let price: Double
    let rating: Double
    let imageURL: String
    let description: String
    
    static let sampleProducts: [Product] = [
        Product(
            id: "1",
            name: "iPhone 15 Pro",
            category: "Electronics",
            price: 999.99,
            rating: 4.8,
            imageURL: "https://via.placeholder.com/200",
            description: "Latest iPhone with advanced camera system"
        ),
        Product(
            id: "2",
            name: "Nike Air Max",
            category: "Clothing",
            price: 129.99,
            rating: 4.5,
            imageURL: "https://via.placeholder.com/200",
            description: "Comfortable running shoes"
        ),
        Product(
            id: "3",
            name: "Coffee Table",
            category: "Home",
            price: 299.99,
            rating: 4.2,
            imageURL: "https://via.placeholder.com/200",
            description: "Modern wooden coffee table"
        ),
        Product(
            id: "4",
            name: "Swift Programming Guide",
            category: "Books",
            price: 49.99,
            rating: 4.7,
            imageURL: "https://via.placeholder.com/200",
            description: "Complete guide to Swift programming"
        ),
        Product(
            id: "5",
            name: "MacBook Pro",
            category: "Electronics",
            price: 1999.99,
            rating: 4.9,
            imageURL: "https://via.placeholder.com/200",
            description: "Powerful laptop for professionals"
        )
    ]
}

#Preview {
    ProductListView()
}