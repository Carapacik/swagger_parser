class GenerationStatistics {
  GenerationStatistics({
    required this.totalFiles,
    required this.totalLines,
    required this.totalRestClients,
    required this.totalRequests,
    required this.totalDataClasses,
    required this.timeElapsed,
  });

  final int totalFiles;
  final int totalLines;
  final int totalRestClients;
  final int totalRequests;
  final int totalDataClasses;
  final Duration timeElapsed;

  GenerationStatistics merge(GenerationStatistics other) {
    return GenerationStatistics(
      totalFiles: totalFiles + other.totalFiles,
      totalLines: totalLines + other.totalLines,
      totalRestClients: totalRestClients + other.totalRestClients,
      totalRequests: totalRequests + other.totalRequests,
      totalDataClasses: totalDataClasses + other.totalDataClasses,
      timeElapsed: timeElapsed + other.timeElapsed,
    );
  }
}
