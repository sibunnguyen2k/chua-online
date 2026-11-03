'use strict';

/** Ném lỗi nếu bất kỳ lệnh nào trong MULTI/pipeline thất bại. */
function unwrap(execResult) {
  if (!execResult) throw new Error('redis transaction aborted');
  return execResult.map(([err, value]) => {
    if (err) throw err;
    return value;
  });
}

module.exports = { unwrap };
