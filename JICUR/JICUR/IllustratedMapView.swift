import SwiftUI

struct IllustratedMapView: View {
    var scene: MapScene

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 0.95, green: 0.94, blue: 0.89)))
            drawFields(context: &context, size: size)
            drawRiver(context: &context, size: size)
            drawRoads(context: &context, size: size)
            drawForest(context: &context, size: size)
            if !scene.route.isEmpty {
                drawRoute(context: &context, size: size)
                drawMarkers(context: &context, size: size)
            }
        }
        .overlay(alignment: .topTrailing) {
            VStack(spacing: 0) {
                Image(systemName: "arrowtriangle.up.fill").font(.caption)
                Text("N").font(.system(size: 8, weight: .bold))
            }
            .foregroundStyle(.black.opacity(0.58))
            .padding(.top, 112).padding(.trailing, 28)
        }
    }

    private func drawFields(context: inout GraphicsContext, size: CGSize) {
        let blocks = [CGRect(x: size.width * 0.08, y: size.height * 0.12, width: size.width * 0.28, height: size.height * 0.21), CGRect(x: size.width * 0.44, y: size.height * 0.08, width: size.width * 0.42, height: size.height * 0.26), CGRect(x: size.width * 0.50, y: size.height * 0.43, width: size.width * 0.38, height: size.height * 0.28), CGRect(x: size.width * 0.12, y: size.height * 0.57, width: size.width * 0.29, height: size.height * 0.25)]
        for (index, rect) in blocks.enumerated() {
            let path = Path(roundedRect: rect, cornerRadius: 24)
            context.fill(path, with: .color(index.isMultiple(of: 2) ? Color.white.opacity(0.26) : Color(red: 0.87, green: 0.87, blue: 0.80).opacity(0.36)))
            context.stroke(path, with: .color(.white.opacity(0.6)), lineWidth: 2)
        }
    }

    private func drawRiver(context: inout GraphicsContext, size: CGSize) {
        var river = Path()
        river.move(to: CGPoint(x: size.width * 0.93, y: -20))
        river.addCurve(to: CGPoint(x: size.width * 0.84, y: size.height * 0.47), control1: CGPoint(x: size.width * 0.72, y: size.height * 0.17), control2: CGPoint(x: size.width * 1.02, y: size.height * 0.29))
        river.addCurve(to: CGPoint(x: size.width * 0.72, y: size.height * 1.05), control1: CGPoint(x: size.width * 0.64, y: size.height * 0.67), control2: CGPoint(x: size.width * 0.94, y: size.height * 0.82))
        context.stroke(river, with: .color(Color(red: 0.14, green: 0.17, blue: 0.16)), lineWidth: 64)
    }

    private func drawRoads(context: inout GraphicsContext, size: CGSize) {
        let lines: [[CGPoint]] = [
            [.init(x: -20, y: size.height * 0.42), .init(x: size.width * 0.45, y: size.height * 0.36), .init(x: size.width, y: size.height * 0.21)],
            [.init(x: size.width * 0.18, y: 0), .init(x: size.width * 0.23, y: size.height * 0.48), .init(x: size.width * 0.10, y: size.height)],
            [.init(x: 0, y: size.height * 0.73), .init(x: size.width * 0.49, y: size.height * 0.62), .init(x: size.width, y: size.height * 0.69)]
        ]
        for line in lines {
            var path = Path(); path.move(to: line[0]); line.dropFirst().forEach { path.addLine(to: $0) }
            context.stroke(path, with: .color(.white.opacity(0.84)), style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))
            context.stroke(path, with: .color(.black.opacity(0.07)), style: StrokeStyle(lineWidth: 1, lineCap: .round))
        }
    }

    private func drawForest(context: inout GraphicsContext, size: CGSize) {
        let centers = [CGPoint(x: size.width * 0.04, y: size.height * 0.10), .init(x: size.width * 0.10, y: size.height * 0.23), .init(x: size.width * 0.04, y: size.height * 0.88), .init(x: size.width * 0.42, y: size.height * 0.83)]
        for center in centers {
            for index in 0..<18 {
                let x = center.x + CGFloat((index * 37) % 110) - 45
                let y = center.y + CGFloat((index * 61) % 130) - 55
                let diameter = CGFloat(34 + (index % 4) * 9)
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: diameter, height: diameter)), with: .color(Color(red: 0.10, green: 0.13, blue: 0.11).opacity(0.88)))
            }
        }
    }

    private func drawRoute(context: inout GraphicsContext, size: CGSize) {
        let points = [CGPoint(x: size.width * 0.24, y: size.height * 0.26), .init(x: size.width * 0.24, y: size.height * 0.37), .init(x: size.width * 0.42, y: size.height * 0.37), .init(x: size.width * 0.42, y: size.height * 0.51), .init(x: size.width * 0.55, y: size.height * 0.56), .init(x: size.width * 0.66, y: size.height * 0.49), .init(x: size.width * 0.69, y: size.height * 0.62), .init(x: size.width * 0.84, y: size.height * 0.72)]
        var path = Path(); path.move(to: points[0]); points.dropFirst().forEach { path.addLine(to: $0) }
        context.stroke(path, with: .color(.black.opacity(0.13)), style: StrokeStyle(lineWidth: 14, lineCap: .round, lineJoin: .round))
        context.stroke(path, with: .color(.jicurGreen), style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
        context.stroke(path, with: .color(.white.opacity(0.68)), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [2, 14]))
    }

    private func drawMarkers(context: inout GraphicsContext, size: CGSize) {
        let markers: [(CGPoint, Color, String)] = [(.init(x: size.width * 0.24, y: size.height * 0.26), .jicurMint, "figure.walk"), (.init(x: size.width * 0.55, y: size.height * 0.49), .cyan.opacity(0.75), "wind"), (.init(x: size.width * 0.69, y: size.height * 0.62), .orange.opacity(0.85), "sun.horizon.fill"), (.init(x: size.width * 0.84, y: size.height * 0.72), .jicurGreen, "house.fill")]
        for marker in markers {
            let rect = CGRect(x: marker.0.x - 23, y: marker.0.y - 23, width: 46, height: 46)
            context.fill(Path(ellipseIn: rect), with: .color(marker.1))
            if let symbol = context.resolveSymbol(id: marker.2) { context.draw(symbol, at: marker.0) }
        }
    }
}
