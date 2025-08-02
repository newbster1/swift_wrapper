import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @State private var quantity = 1
    @State private var isFavorite = false
    @State private var showingAddToCart = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Product Image
                AsyncImage(url: URL(string: product.imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(1, contentMode: .fit)
                }
                .frame(height: 300)
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 12) {
                    // Product Info
                    HStack {
                        VStack(alignment: .leading) {
                            Text(product.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(product.category)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            isFavorite.toggle()
                            TelemetryService.shared.logUserInteraction(
                                .tap,
                                viewName: "ProductDetail",
                                elementId: "favorite_button"
                            )
                        }) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(isFavorite ? .red : .gray)
                                .font(.title2)
                        }
                    }
                    
                    // Rating and Price
                    HStack {
                        HStack(spacing: 4) {
                            ForEach(0..<5) { index in
                                Image(systemName: "star.fill")
                                    .foregroundColor(index < Int(product.rating) ? .yellow : .gray.opacity(0.3))
                                    .font(.caption)
                            }
                            Text("\(product.rating, specifier: "%.1f")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("$\(product.price, specifier: "%.2f")")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    
                    // Description
                    Text("Description")
                        .font(.headline)
                        .padding(.top)
                    
                    Text(product.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    // Quantity Selector
                    HStack {
                        Text("Quantity")
                            .font(.headline)
                        
                        Spacer()
                        
                        HStack {
                            Button(action: {
                                if quantity > 1 {
                                    quantity -= 1
                                    TelemetryService.shared.logUserInteraction(
                                        .tap,
                                        viewName: "ProductDetail",
                                        elementId: "quantity_stepper"
                                    )
                                }
                            }) {
                                Image(systemName: "minus.circle")
                                    .font(.title2)
                            }
                            .disabled(quantity <= 1)
                            
                            Text("\(quantity)")
                                .font(.headline)
                                .frame(minWidth: 30)
                            
                            Button(action: {
                                quantity += 1
                                TelemetryService.shared.logUserInteraction(
                                    .tap,
                                    viewName: "ProductDetail",
                                    elementId: "quantity_stepper"
                                )
                            }) {
                                Image(systemName: "plus.circle")
                                    .font(.title2)
                            }
                        }
                    }
                    .padding(.top)
                    
                    // Add to Cart Button
                    Button(action: {
                        showingAddToCart = true
                        TelemetryService.shared.logUserInteraction(
                            .tap,
                            viewName: "ProductDetail",
                            elementId: "add_to_cart_button"
                        )
                        
                        TelemetryService.shared.logEvent(
                            name: "product_added_to_cart",
                            category: EventCategory.user,
                            attributes: [
                                "product_id": product.id,
                                "product_name": product.name,
                                "quantity": quantity,
                                "total_price": product.price * Double(quantity)
                            ]
                        )
                    }) {
                        HStack {
                            Image(systemName: "cart.badge.plus")
                            Text("Add to Cart")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.top)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            TelemetryService.shared.logEvent(
                name: "product_detail_viewed",
                category: EventCategory.navigation,
                attributes: [
                    "product_id": product.id,
                    "product_name": product.name,
                    "product_category": product.category
                ]
            )
        }
        .alert("Added to Cart", isPresented: $showingAddToCart) {
            Button("OK") { }
        } message: {
            Text("\(quantity) x \(product.name) added to cart")
        }
    }
}

#Preview {
    NavigationView {
        ProductDetailView(product: Product.sampleProducts[0])
    }
}