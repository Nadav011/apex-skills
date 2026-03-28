#!/usr/bin/env node
/**
 * RTL AST Analyzer v2.0
 * AST-based detection of RTL violations in TSX/JSX/CSS files
 * Part of APEX Law #5 Enforcement
 */

const fs = require('fs');
const path = require('path');

// Violation patterns with suggestions
const TAILWIND_VIOLATIONS = {
  // Margin violations
  'ml-': { suggestion: 'ms-', severity: 'error', category: 'margin' },
  'mr-': { suggestion: 'me-', severity: 'error', category: 'margin' },
  // Padding violations
  'pl-': { suggestion: 'ps-', severity: 'error', category: 'padding' },
  'pr-': { suggestion: 'pe-', severity: 'error', category: 'padding' },
  // Position violations (use inset-s-*/inset-e-* which generate inset-inline-start/inset-inline-end in TW 4.2)
  // Note: start-*/end-* are deprecated in TW 4.2 (still work, gradual phase-out)
  'left-': { suggestion: 'inset-s-', severity: 'error', category: 'position' },
  'right-': { suggestion: 'inset-e-', severity: 'error', category: 'position' },
  'inset-l-': { suggestion: 'inset-s-', severity: 'error', category: 'position' },
  'inset-r-': { suggestion: 'inset-e-', severity: 'error', category: 'position' },
  // Text alignment
  'text-left': { suggestion: 'text-start', severity: 'error', category: 'text' },
  'text-right': { suggestion: 'text-end', severity: 'error', category: 'text' },
  // Float
  'float-left': { suggestion: 'float-start', severity: 'error', category: 'float' },
  'float-right': { suggestion: 'float-end', severity: 'error', category: 'float' },
  // Border radius
  'rounded-l-': { suggestion: 'rounded-s-', severity: 'error', category: 'border' },
  'rounded-r-': { suggestion: 'rounded-e-', severity: 'error', category: 'border' },
  'rounded-tl-': { suggestion: 'rounded-ss-', severity: 'error', category: 'border' },
  'rounded-tr-': { suggestion: 'rounded-se-', severity: 'error', category: 'border' },
  'rounded-bl-': { suggestion: 'rounded-es-', severity: 'error', category: 'border' },
  'rounded-br-': { suggestion: 'rounded-ee-', severity: 'error', category: 'border' },
  // Border
  'border-l-': { suggestion: 'border-s-', severity: 'error', category: 'border' },
  'border-r-': { suggestion: 'border-e-', severity: 'error', category: 'border' },
  // Scroll
  'scroll-ml-': { suggestion: 'scroll-ms-', severity: 'error', category: 'scroll' },
  'scroll-mr-': { suggestion: 'scroll-me-', severity: 'error', category: 'scroll' },
  'scroll-pl-': { suggestion: 'scroll-ps-', severity: 'error', category: 'scroll' },
  'scroll-pr-': { suggestion: 'scroll-pe-', severity: 'error', category: 'scroll' },
  // Divide
  'divide-x-': { suggestion: 'Check RTL behavior', severity: 'warning', category: 'divide' },
  // Space (warning only - context dependent)
  'space-x-': { suggestion: 'Verify RTL behavior', severity: 'warning', category: 'space' },
};

// CSS property violations
const CSS_VIOLATIONS = {
  'margin-left': { suggestion: 'margin-inline-start', severity: 'error', category: 'margin' },
  'margin-right': { suggestion: 'margin-inline-end', severity: 'error', category: 'margin' },
  'padding-left': { suggestion: 'padding-inline-start', severity: 'error', category: 'padding' },
  'padding-right': { suggestion: 'padding-inline-end', severity: 'error', category: 'padding' },
  'left:': { suggestion: 'inset-inline-start', severity: 'error', category: 'position' },
  'right:': { suggestion: 'inset-inline-end', severity: 'error', category: 'position' },
  'text-align: left': { suggestion: 'text-align: start', severity: 'error', category: 'text' },
  'text-align: right': { suggestion: 'text-align: end', severity: 'error', category: 'text' },
  'float: left': { suggestion: 'float: inline-start', severity: 'error', category: 'float' },
  'float: right': { suggestion: 'float: inline-end', severity: 'error', category: 'float' },
  'border-left': { suggestion: 'border-inline-start', severity: 'error', category: 'border' },
  'border-right': { suggestion: 'border-inline-end', severity: 'error', category: 'border' },
  'border-top-left-radius': { suggestion: 'border-start-start-radius', severity: 'error', category: 'border' },
  'border-top-right-radius': { suggestion: 'border-start-end-radius', severity: 'error', category: 'border' },
  'border-bottom-left-radius': { suggestion: 'border-end-start-radius', severity: 'error', category: 'border' },
  'border-bottom-right-radius': { suggestion: 'border-end-end-radius', severity: 'error', category: 'border' },
};

// Directional icons that need rtl:rotate-180
const DIRECTIONAL_ICONS = [
  'ChevronLeft', 'ChevronRight',
  'ArrowLeft', 'ArrowRight',
  'ArrowLeftIcon', 'ArrowRightIcon',
  'ChevronLeftIcon', 'ChevronRightIcon',
  'CaretLeft', 'CaretRight',
  'DoubleArrowLeft', 'DoubleArrowRight',
  'ForwardIcon', 'BackIcon',
  'NextIcon', 'PrevIcon',
  'LuChevronLeft', 'LuChevronRight',
  'LuArrowLeft', 'LuArrowRight',
  'FiChevronLeft', 'FiChevronRight',
  'FiArrowLeft', 'FiArrowRight',
  'HiChevronLeft', 'HiChevronRight',
  'HiArrowLeft', 'HiArrowRight',
  'IoChevronBack', 'IoChevronForward',
  'MdChevronLeft', 'MdChevronRight',
  'MdArrowBack', 'MdArrowForward',
  'BiChevronLeft', 'BiChevronRight',
  'BiLeftArrow', 'BiRightArrow',
];

/**
 * Parse file content and extract violations using AST-like analysis
 */
function analyzeFile(filePath, content) {
  const violations = [];
  const lines = content.split('\n');
  const ext = path.extname(filePath).toLowerCase();
  
  // Track if file has directional icons
  let hasDirectionalIcon = false;
  let hasRtlRotate = false;
  
  lines.forEach((line, index) => {
    const lineNum = index + 1;
    
    // Skip comments
    if (line.trim().startsWith('//') || line.trim().startsWith('/*') || line.trim().startsWith('*')) {
      return;
    }
    
    // Check for Tailwind violations in className/class attributes
    if (ext === '.tsx' || ext === '.jsx' || ext === '.ts' || ext === '.js') {
      // Extract className values
      const classNameMatches = line.matchAll(/className\s*=\s*[{"`']([^`"'}]+)[`"'}]|class\s*=\s*["']([^"']+)["']/g);
      
      for (const match of classNameMatches) {
        const classValue = match[1] || match[2];
        if (classValue) {
          analyzeClassString(classValue, lineNum, line, filePath, violations);
        }
      }
      
      // Check template literals with cn(), clsx(), twMerge()
      const cnMatches = line.matchAll(/(?:cn|clsx|twMerge|cx)\s*\(\s*[`'"]([^`'"]+)[`'"]/g);
      for (const match of cnMatches) {
        if (match[1]) {
          analyzeClassString(match[1], lineNum, line, filePath, violations);
        }
      }
      
      // Check for styled-components / emotion
      const styledMatches = line.matchAll(/(?:css|styled)[^`]*`([^`]+)`/g);
      for (const match of styledMatches) {
        if (match[1]) {
          analyzeCSSString(match[1], lineNum, line, filePath, violations);
        }
      }
      
      // Check for directional icons
      for (const icon of DIRECTIONAL_ICONS) {
        if (line.includes(icon) || line.includes(`<${icon}`)) {
          hasDirectionalIcon = true;
        }
      }
      
      // Check for rtl:rotate-180
      if (line.includes('rtl:rotate-180') || line.includes('rtl:-rotate-180')) {
        hasRtlRotate = true;
      }
      
      // Check inline styles
      const styleMatches = line.matchAll(/style\s*=\s*\{\{([^}]+)\}\}/g);
      for (const match of styleMatches) {
        if (match[1]) {
          analyzeInlineStyle(match[1], lineNum, line, filePath, violations);
        }
      }
    }
    
    // Check CSS/SCSS files
    if (ext === '.css' || ext === '.scss') {
      analyzeCSSString(line, lineNum, line, filePath, violations);
    }
  });
  
  // Add warning if directional icons found without rtl:rotate-180
  if (hasDirectionalIcon && !hasRtlRotate) {
    violations.push({
      file: filePath,
      line: 1,
      column: 1,
      violation: 'directional-icon-without-rtl',
      originalValue: 'Directional icon component',
      suggestion: 'Add rtl:rotate-180 class to directional icons',
      severity: 'warning',
      category: 'icon',
      context: 'File contains directional icons without rtl:rotate-180'
    });
  }
  
  return violations;
}

/**
 * Analyze a class string for Tailwind violations
 */
function analyzeClassString(classString, lineNum, fullLine, filePath, violations) {
  const classes = classString.split(/\s+/);
  
  classes.forEach(cls => {
    // Skip RTL-aware classes
    if (cls.startsWith('rtl:') || cls.startsWith('ltr:')) {
      return;
    }
    
    // Skip already logical classes
    if (cls.includes('ms-') || cls.includes('me-') || cls.includes('ps-') || cls.includes('pe-') ||
        cls.includes('inset-s-') || cls.includes('inset-e-') ||
        cls.includes('start-') || cls.includes('end-') || // deprecated but still valid in TW 4.2
        cls.includes('text-start') || cls.includes('text-end')) {
      return;
    }
    
    for (const [pattern, info] of Object.entries(TAILWIND_VIOLATIONS)) {
      // Check for exact matches or prefix matches
      const isMatch = pattern.endsWith('-') 
        ? cls.startsWith(pattern) || cls.match(new RegExp(`^${pattern.slice(0, -1)}(\\[|$)`))
        : cls === pattern || cls.startsWith(pattern + '-') || cls.startsWith(pattern + '[');
      
      if (isMatch) {
        const column = fullLine.indexOf(cls) + 1;
        const suggestion = generateSuggestion(cls, pattern, info.suggestion);
        
        violations.push({
          file: filePath,
          line: lineNum,
          column: column > 0 ? column : 1,
          violation: pattern.replace('-', ''),
          originalValue: cls,
          suggestion: suggestion,
          severity: info.severity,
          category: info.category,
          context: fullLine.trim().substring(0, 100)
        });
      }
    }
  });
}

/**
 * Analyze CSS string for violations
 */
function analyzeCSSString(cssString, lineNum, fullLine, filePath, violations) {
  const normalizedCSS = cssString.toLowerCase();
  
  for (const [pattern, info] of Object.entries(CSS_VIOLATIONS)) {
    if (normalizedCSS.includes(pattern.toLowerCase())) {
      const column = fullLine.toLowerCase().indexOf(pattern.toLowerCase()) + 1;
      
      violations.push({
        file: filePath,
        line: lineNum,
        column: column > 0 ? column : 1,
        violation: pattern.replace(':', '').trim(),
        originalValue: pattern,
        suggestion: info.suggestion,
        severity: info.severity,
        category: info.category,
        context: fullLine.trim().substring(0, 100)
      });
    }
  }
}

/**
 * Analyze inline style objects
 */
function analyzeInlineStyle(styleString, lineNum, fullLine, filePath, violations) {
  const cssPropertyMap = {
    'marginLeft': { suggestion: 'marginInlineStart', severity: 'error' },
    'marginRight': { suggestion: 'marginInlineEnd', severity: 'error' },
    'paddingLeft': { suggestion: 'paddingInlineStart', severity: 'error' },
    'paddingRight': { suggestion: 'paddingInlineEnd', severity: 'error' },
    'left': { suggestion: 'insetInlineStart', severity: 'error' },
    'right': { suggestion: 'insetInlineEnd', severity: 'error' },
    'borderLeft': { suggestion: 'borderInlineStart', severity: 'error' },
    'borderRight': { suggestion: 'borderInlineEnd', severity: 'error' },
    'textAlign': { check: ['left', 'right'], suggestion: 'start/end', severity: 'error' },
  };
  
  for (const [prop, info] of Object.entries(cssPropertyMap)) {
    if (styleString.includes(prop)) {
      // Special handling for textAlign
      if (prop === 'textAlign') {
        if (styleString.includes("'left'") || styleString.includes('"left"') ||
            styleString.includes("'right'") || styleString.includes('"right"')) {
          violations.push({
            file: filePath,
            line: lineNum,
            column: fullLine.indexOf(prop) + 1,
            violation: 'textAlign-physical',
            originalValue: prop,
            suggestion: `Use textAlign: 'start' or 'end' instead of 'left'/'right'`,
            severity: info.severity,
            category: 'text',
            context: fullLine.trim().substring(0, 100)
          });
        }
      } else {
        violations.push({
          file: filePath,
          line: lineNum,
          column: fullLine.indexOf(prop) + 1,
          violation: prop,
          originalValue: prop,
          suggestion: info.suggestion,
          severity: info.severity,
          category: 'inline-style',
          context: fullLine.trim().substring(0, 100)
        });
      }
    }
  }
}

/**
 * Generate proper suggestion based on original class
 */
function generateSuggestion(original, pattern, baseSuggestion) {
  if (baseSuggestion.includes('Check') || baseSuggestion.includes('Verify')) {
    return baseSuggestion;
  }
  
  // Handle pattern replacement
  if (pattern.endsWith('-')) {
    return original.replace(pattern.slice(0, -1), baseSuggestion.slice(0, -1));
  }
  
  return original.replace(pattern, baseSuggestion);
}

/**
 * Auto-fix a single file
 */
function fixFile(filePath, content) {
  let fixed = content;
  let fixCount = 0;
  
  // Tailwind class replacements
  const tailwindReplacements = [
    // Margin
    [/\bml-(\d+|\[)/g, 'ms-$1'],
    [/\bmr-(\d+|\[)/g, 'me-$1'],
    // Padding  
    [/\bpl-(\d+|\[)/g, 'ps-$1'],
    [/\bpr-(\d+|\[)/g, 'pe-$1'],
    // Position (inset-s-*/inset-e-* generate inset-inline-start/inset-inline-end in TW 4.2)
    [/\bleft-(\d+|\[)/g, 'inset-s-$1'],
    [/\bright-(\d+|\[)/g, 'inset-e-$1'],
    [/\binset-l-/g, 'inset-s-'],
    [/\binset-r-/g, 'inset-e-'],
    // Text
    [/\btext-left\b/g, 'text-start'],
    [/\btext-right\b/g, 'text-end'],
    // Float
    [/\bfloat-left\b/g, 'float-start'],
    [/\bfloat-right\b/g, 'float-end'],
    // Border radius
    [/\brounded-l-/g, 'rounded-s-'],
    [/\brounded-r-/g, 'rounded-e-'],
    [/\brounded-tl-/g, 'rounded-ss-'],
    [/\brounded-tr-/g, 'rounded-se-'],
    [/\brounded-bl-/g, 'rounded-es-'],
    [/\brounded-br-/g, 'rounded-ee-'],
    // Border
    [/\bborder-l-/g, 'border-s-'],
    [/\bborder-r-/g, 'border-e-'],
    // Scroll
    [/\bscroll-ml-/g, 'scroll-ms-'],
    [/\bscroll-mr-/g, 'scroll-me-'],
    [/\bscroll-pl-/g, 'scroll-ps-'],
    [/\bscroll-pr-/g, 'scroll-pe-'],
  ];
  
  for (const [pattern, replacement] of tailwindReplacements) {
    const matches = fixed.match(pattern);
    if (matches) {
      fixCount += matches.length;
      fixed = fixed.replace(pattern, replacement);
    }
  }
  
  return { content: fixed, fixCount };
}

/**
 * Main execution
 */
function main() {
  const args = process.argv.slice(2);
  
  if (args.includes('--help') || args.includes('-h')) {
    console.log(`
RTL AST Analyzer - APEX Law #5 Enforcement

Usage: node ast-analyzer.js [options] <file|->

Options:
  --fix         Output fixed content instead of violations
  --json        Output as JSON
  --help, -h    Show this help message

Input:
  <file>        Path to file to analyze
  -             Read from stdin
`);
    process.exit(0);
  }
  
  const fixMode = args.includes('--fix');
  const jsonMode = args.includes('--json');
  const fileArg = args.find(a => !a.startsWith('-'));
  
  let content;
  let filePath;
  
  if (fileArg === '-' || !fileArg) {
    // Read from stdin
    content = fs.readFileSync(0, 'utf-8');
    filePath = 'stdin';
  } else {
    filePath = fileArg;
    if (!fs.existsSync(filePath)) {
      console.error(`Error: File not found: ${filePath}`);
      process.exit(1);
    }
    content = fs.readFileSync(filePath, 'utf-8');
  }
  
  if (fixMode) {
    const { content: fixedContent, fixCount } = fixFile(filePath, content);
    if (jsonMode) {
      console.log(JSON.stringify({ fixCount, content: fixedContent }));
    } else {
      process.stdout.write(fixedContent);
    }
  } else {
    const violations = analyzeFile(filePath, content);
    if (jsonMode) {
      console.log(JSON.stringify(violations, null, 2));
    } else {
      violations.forEach(v => {
        console.log(`${v.file}:${v.line}:${v.column} [${v.severity.toUpperCase()}] ${v.originalValue} -> ${v.suggestion}`);
      });
    }
    process.exit(violations.filter(v => v.severity === 'error').length > 0 ? 1 : 0);
  }
}

// Export for use as module
module.exports = { analyzeFile, fixFile, TAILWIND_VIOLATIONS, CSS_VIOLATIONS };

// Run if executed directly
if (require.main === module) {
  main();
}
