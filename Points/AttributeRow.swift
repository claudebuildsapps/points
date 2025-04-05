import SwiftUI

/// A reusable key-value attribute row with consistent styling
struct AttributeRow: View {
    var name: String
    var value: String
    var color: Color
    var keyWidth: CGFloat? = nil
    
    var body: some View {
        HStack(spacing: 8) {
            // Key in left column
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary.opacity(0.65))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(color.opacity(0.1))
                .cornerRadius(8)
            
            // Value in right column
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary.opacity(0.65))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .background(color.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    VStack {
        AttributeRow(name: "Date", value: "April 1st, 2025", color: .blue)
        AttributeRow(name: "Points", value: "42", color: .green)
        AttributeRow(name: "Status", value: "Active", color: .orange)
    }
    .padding()
}