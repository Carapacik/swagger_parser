/// Contains statistics about generation
class GenerationStatistics {
  /// Constructor for [GenerationStatistics]
  const GenerationStatistics({
    required this.totalFiles,
    required this.totalLines,
    required this.totalRestClients,
    required this.totalRequests,
    required this.totalDataClasses,
    required this.timeElapsed,
  });

  /// Total files
  final int totalFiles;

  /// Total lines of code
  final int totalLines;

  /// Total rest clients
  final int totalRestClients;

  /// Total requests
  final int totalRequests;

  /// Total data classes
  final int totalDataClasses;

  /// Time elapsed for generation
  final Duration timeElapsed;

  /// Merge two [GenerationStatistics] into one
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
