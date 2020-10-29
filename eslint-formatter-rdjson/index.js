// ESLint Formatter to Output Reviewdog Diagnostic Format (RDFormat)
// https://github.com/reviewdog/reviewdog/blob/1d8f6d6897dcfa67c33a2ccdc2ea23a8cca96c8c/proto/rdf/reviewdog.proto

// https://github.com/eslint/eslint/blob/091e52ae1ca408f3e668f394c14d214c9ce806e6/lib/shared/types.js#L11
// https://github.com/eslint/eslint/blob/82669fa66670a00988db5b1d10fe8f3bf30be84e/lib/shared/config-validator.js#L40
function convertSeverity(s) {
  if (s === 0) { // off
    return 'INFO';
  } else if (s === 1) {
    return 'WARNING';
  } else if (s === 2) {
    return 'ERROR';
  }
  return 'UNKNOWN_SEVERITY';
}

function utf8length(str) {
  return unescape(encodeURIComponent(str)).length;
}

function positionFromUTF16CodeUnitOffset(offset, text) {
  const lines = text.split('\n');
  let lnum = 1;
  let column = 0;
  let lengthSoFar = 0;
  for (const line of lines) {
    if (offset <= lengthSoFar + line.length) {
      const lineText = line.slice(0, offset-lengthSoFar);
      // +1 because eslint offset is a bit weird and will append text right
      // after the offset.
      column = utf8length(lineText) + 1;
      break;
    }
    lengthSoFar += line.length + 1; // +1 for line-break.
    lnum++;
  }
  return {line: lnum, column: column};
}

function positionFromLineAndUTF16CodeUnitOffsetColumn(line, column, sourceLines) {
  let col = 0;
  if (sourceLines.length >= line) {
    const lineText = sourceLines[line-1].slice(0, column);
    col = utf8length(lineText);
  }
  return {line: line, column: col};
}

function commonSuffixLength(str1, str2) {
  let i = 0;
  for (i = 0; i < str1.length && i < str2.length; ++i) {
    if (str1[str1.length-(i+1)] !== str2[str2.length-(i+1)]) {
      break;
    }
  }
  return i;
}

function buildMinimumSuggestion(fix, source) {
  const l = commonSuffixLength(fix.text, source.slice(fix.range[0], fix.range[1]));
  return {
    range: {
      start: positionFromUTF16CodeUnitOffset(fix.range[0], source),
      end: positionFromUTF16CodeUnitOffset(fix.range[1] - l, source)
    },
    text: fix.text.slice(0, fix.text.length - l)
  };
}

module.exports = function (results, data) {
  const rdjson = {
    source: {
      name: 'eslint',
      url: 'https://eslint.org/'
    },
    diagnostics: []
  };

  results.forEach(result => {
    const filePath = result.filePath;
    const source = result.source;
    const sourceLines = source ? source.split('\n') : [];
    result.messages.forEach(msg => {
      let diagnostic = {
        message: msg.message,
        location: {
          path: filePath,
          range: {
            start: positionFromLineAndUTF16CodeUnitOffsetColumn(msg.line, msg.column, sourceLines),
            end:positionFromLineAndUTF16CodeUnitOffsetColumn(msg.endLine, msg.endColumn, sourceLines)
          }
        },
        severity: convertSeverity(msg.severity),
        code: {
          value: msg.ruleId,
          url: (data.rulesMeta[msg.ruleId] && data.rulesMeta[msg.ruleId].docs ? data.rulesMeta[msg.ruleId].docs.url : '')
        },
        original_output: JSON.stringify(msg)
      };

      if (msg.fix) {
        diagnostic.suggestions = [buildMinimumSuggestion(msg.fix, source)];
      }

      rdjson.diagnostics.push(diagnostic);
    });
  });
  return JSON.stringify(rdjson);
};
