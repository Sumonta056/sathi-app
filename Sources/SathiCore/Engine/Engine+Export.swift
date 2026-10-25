import Foundation

extension Engine {
    package func export(
        _ format: ExportFormat,
        screen: ReportScreen,
        to exporter: FileExporter,
        renderer: SummaryRenderer
    ) async -> ExportOutcome {
        let stamp = clock.now.wholeSecond
        let name = ExportNames.fileName(format, on: stamp, calendar: calendar)
        guard let url = await exporter.destination(suggestedName: name, format: format) else { return .cancelled }
        switch format {
        case .pdf:
            guard let data = renderer.pdf(for: screen) else { return .failed }
            return await Task.detached { ExportJob.write(data, to: url) }.value
        case .csv, .json:
            let job = ExportJob(
                history: history,
                prefs: data.prefs,
                live: data.live,
                exportedAt: clock.now.wholeSecond,
                timeZone: calendar.timeZone
            )
            return await Task.detached { job.write(format, to: url) }.value
        }
    }
}
