import SwiftUI

// A button styled as a text field that opens the numeric keyboard
struct NumericField: View {
    var label: String
    @Binding var text: String
    var isDecimal: Bool
    var foregroundColor: Color
    var onActivate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Button(action: onActivate) {
                HStack {
                    Text(text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(foregroundColor)
                    Spacer()
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                        .background(Color(.systemBackground))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

#Preview {
    NumericField(
        label: "Points",
        text: .constant("5.0"),
        isDecimal: true,
        foregroundColor: .green,
        onActivate: {}
    )
    .padding()
}
