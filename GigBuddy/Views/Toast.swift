import SwiftUI

struct Toast: View {
    enum ToastType {
        case info
        case success
        case error
        
        var iconName: String {
            switch self {
            case .info: return "info.circle.fill"
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.circle.fill"
            }
        }
        
        var tintColor: Color {
            switch self {
            case .info: return .blue
            case .success: return .green
            case .error: return .red
            }
        }
    }
    
    let type: ToastType
    let title: String
    let message: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: type.iconName)
                    .foregroundColor(type.tintColor)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 8)
    }
}

struct ToastModifier: ViewModifier {
    @Binding var isPresenting: Bool
    let toast: () -> Toast
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    if isPresenting {
                        toast()
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    withAnimation {
                                        isPresenting = false
                                    }
                                }
                            }
                    }
                }
                , alignment: .top
            )
    }
}

extension View {
    func toast(isPresenting: Binding<Bool>, toast: @escaping () -> Toast) -> some View {
        modifier(ToastModifier(isPresenting: isPresenting, toast: toast))
    }
} 