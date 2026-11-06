/// XP for an activity worth [max]: a first-try answer counts fully, an answer
/// recovered after a miss counts half.
int scoreXp({
  required int firstTry,
  required int recovered,
  required int total,
  int max = 20,
}) => (max * (firstTry + recovered * 0.5) / total).round();
