module.exports = {
  root: true,
  parser: '@typescript-eslint/parser',
  parserOptions: {
    tsconfigRootDir: __dirname,
    project: ['./tsconfig.json'],
  },
  plugins: [
    '@typescript-eslint',
  ],
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:@typescript-eslint/recommended-requiring-type-checking',
  ],
  rules: {
    "no-extra-semi": "off",
    "@typescript-eslint/semi": ["error"],
    "@typescript-eslint/no-extra-semi": ["error"],
    "brace-style": "off",
    "@typescript-eslint/brace-style": ["error"],
    "no-loss-of-precision": "off",
    "@typescript-eslint/no-loss-of-precision": ["error"],
    "space-infix-ops": "off",
    "@typescript-eslint/space-infix-ops": ["error", { "int32Hint": false }],
    "@typescript-eslint/no-misused-new": "error",
    "quotes": "off",
    "@typescript-eslint/quotes": ["error"]
  }
};
