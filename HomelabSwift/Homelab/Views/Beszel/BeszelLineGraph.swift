import SwiftUI

struct SmoothLineGraph: View {
    let data: [Double]
    var secondaryData: [Double]? = nil
    var graphColor: Color = Color(hex: "#0EA5E9")
    var secondaryColor: Color = .purple
    var height: CGFloat = 120
    var enableScrub: Bool = true
    var labelFormatter: ((Double) -> String)? = nil
    var secondaryLabelFormatter: ((Double) -> String)? = nil

    @State private var scrubIndex: Int? = nil
    @State private var appeared = false

    var body: some View {
        if data.count < 2 {
            RoundedRectangle(cornerRadius: 8)
                .fill(graphColor.opacity(0.05))
                .frame(height: height)
                .overlay {
                    Text("Not enough data")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
        } else {
            VStack(spacing: 6) {
                // Tooltip
                if let idx = scrubIndex, idx < data.count {
                    HStack(spacing: 12) {
                        if let formatter = labelFormatter {
                            Text(formatter(data[idx]))
                                .font(.caption.bold())
                                .foregroundStyle(graphColor)
                        }
                        if let sec = secondaryData, idx < sec.count, let formatter = secondaryLabelFormatter {
                            Text(formatter(sec[idx]))
                                .font(.caption.bold())
                                .foregroundStyle(secondaryColor)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                    .transition(.opacity)
                }

                // Graph
                GeometryReader { geo in
                    Canvas { ctx, size in
                        let w = size.width
                        let h = size.height
                    let count = data.count
                    guard count >= 2 else { return }

                    let allValues = data + (secondaryData ?? [])
                    let maxVal = max(allValues.max() ?? 1, 1)
                    let minVal = min(allValues.min() ?? 0, 0)
                    let range = max(maxVal - minVal, 0.001)

                    func xFor(_ i: Int) -> CGFloat {
                        CGFloat(i) / CGFloat(count - 1) * w
                    }
                    func yFor(_ v: Double) -> CGFloat {
                        h - CGFloat((v - minVal) / range) * h * 0.9 - h * 0.05
                    }

                    // Primary line + fill
                    let primaryPath = smoothPath(data: data, size: size, minVal: minVal, range: range)
                    var fillPath = primaryPath
                    fillPath.addLine(to: CGPoint(x: w, y: h))
                    fillPath.addLine(to: CGPoint(x: 0, y: h))
                    fillPath.closeSubpath()

                    let gradient = Gradient(colors: [graphColor.opacity(0.3), graphColor.opacity(0.02)])
                    ctx.fill(fillPath, with: .linearGradient(gradient, startPoint: .init(x: 0, y: 0), endPoint: .init(x: 0, y: h)))
                    ctx.stroke(primaryPath, with: .color(graphColor), lineWidth: 2)

                    // Secondary line
                    if let sec = secondaryData, sec.count >= 2 {
                        let secPath = smoothPath(data: sec, size: size, minVal: minVal, range: range)
                        ctx.stroke(secPath, with: .color(secondaryColor.opacity(0.7)), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    }

                    // Scrub indicator
                    if let idx = scrubIndex, idx < count {
                        let x = xFor(idx)
                        let y = yFor(data[idx])
                        var line = Path()
                        line.move(to: CGPoint(x: x, y: 0))
                        line.addLine(to: CGPoint(x: x, y: h))
                        ctx.stroke(line, with: .color(.white.opacity(0.3)), lineWidth: 1)

                        let circle = Path(ellipseIn: CGRect(x: x - 5, y: y - 5, width: 10, height: 10))
                        ctx.fill(circle, with: .color(graphColor))
                        ctx.stroke(circle, with: .color(.white), lineWidth: 2)
                    }
                    }
                    .frame(height: height)
                    .contentShape(Rectangle())
                    .gesture(
                        enableScrub ?
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let width = max(1, geo.size.width)
                                let fraction = min(max(value.location.x / width, 0), 1)
                                let idx = Int(fraction * CGFloat(data.count - 1))
                                let clamped = max(0, min(data.count - 1, idx))
                                if clamped != scrubIndex {
                                    scrubIndex = clamped
                                    let gen = UIImpactFeedbackGenerator(style: .light)
                                    gen.impactOccurred()
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.easeOut(duration: 0.2)) { scrubIndex = nil }
                            }
                        : nil
                    )
                }
                .frame(height: height)
            }
        }
    }

    private func smoothPath(data: [Double], size: CGSize, minVal: Double, range: Double) -> Path {
        let w = size.width
        let h = size.height
        let count = data.count

        func xFor(_ i: Int) -> CGFloat { CGFloat(i) / CGFloat(count - 1) * w }
        func yFor(_ v: Double) -> CGFloat { h - CGFloat((v - minVal) / range) * h * 0.9 - h * 0.05 }

        var path = Path()
        path.move(to: CGPoint(x: xFor(0), y: yFor(data[0])))

        for i in 1..<count {
            let prev = CGPoint(x: xFor(i - 1), y: yFor(data[i - 1]))
            let curr = CGPoint(x: xFor(i), y: yFor(data[i]))
            let midX = (prev.x + curr.x) / 2
            path.addCurve(
                to: curr,
                control1: CGPoint(x: midX, y: prev.y),
                control2: CGPoint(x: midX, y: curr.y)
            )
        }
        return path
    }
}

// MARK: - Preview-friendly mini version (no scrub)

struct MiniLineGraph: View {
    let data: [Double]
    var color: Color = Color(hex: "#0EA5E9")
    var height: CGFloat = 40

    var body: some View {
        SmoothLineGraph(
            data: data,
            graphColor: color,
            height: height,
            enableScrub: false
        )
    }
}
