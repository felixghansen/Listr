
// Source - https://stackoverflow.com/a
// Posted by jnpdx
// Retrieved 2025-12-19, License - CC BY-SA 4.0

import SwiftUI

struct DynamicTextEditor: View {
    
    @Binding var text: String
    @State var textEditorHeight: CGFloat = 32
    
    var body: some View {
        
        ZStack(alignment: .leading) {
            Text(text)
                .font(.system(.body))
                .foregroundStyle(.clear)
                .padding(8)
                .cornerRadius(6)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear {
                                textEditorHeight = geo.size.height
                            }
                            .onChange(of: geo.size.height) { _, new in
                                textEditorHeight = new
                            }
                    }
                )
            
            TextEditor(text: $text)
                .textFieldStyle(.plain)
                .font(.system(.body))
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
                .foregroundStyle(.secondary)
                .background(.tertiary)
                .cornerRadius(6)
                .scrollContentBackground(.hidden)
                .scrollDisabled(true)
                .frame(height: textEditorHeight)
        }
        
    }
    
}
