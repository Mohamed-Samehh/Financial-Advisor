module.exports = {
  preset: 'jest-preset-angular',
  setupFilesAfterEnv: ['<rootDir>/setup-jest.ts'],
  testPathIgnorePatterns: [
    '/node_modules/',
    '/dist/'
    // Add paths to exclude failing tests if desired
  ],
  testMatch: ['**/*.spec.ts'],
  transformIgnorePatterns: ['node_modules/(?!@angular|rxjs)'],
  collectCoverage: true,
  coverageReporters: ['html', 'lcov', 'text-summary'],
  coverageDirectory: 'coverage'
};
