#!/usr/bin/env Rscript
# ==============================================================================
# Test Linear Algebra Speed with Thread Control
# ==============================================================================
#
# HOW TO RUN:
#
# 1. Set environment variables and run:
#    n=20
#    export OPENBLAS_NUM_THREADS=$n OMP_NUM_THREADS=$n MKL_NUM_THREADS=$n
#    Rscript test_linalg_speed.R
#
# 2. Or in one line:
#    n=20 && export OPENBLAS_NUM_THREADS=$n OMP_NUM_THREADS=$n MKL_NUM_THREADS=$n && Rscript test_linalg_speed.R
#
# 3. To test different thread counts:
#    for n in 1 2 4 8 20; do
#      export OPENBLAS_NUM_THREADS=$n OMP_NUM_THREADS=$n MKL_NUM_THREADS=$n
#      echo "=== Testing with $n threads ==="
#      Rscript test_linalg_speed.R
#    done
#
# ==============================================================================

# Parameters
MATRIX_SIZE <- 1000
N_MATRICES <- 100
N_CORES <- 20

cat("\n")
cat(rep("=", 70), "\n", sep = "")
cat("Linear Algebra Performance Test\n")
cat(rep("=", 70), "\n", sep = "")

# Load library
suppressPackageStartupMessages({
  library(tictoc)
})

# Generate covariance matrices
cat("\nGenerating matrices:\n")
cat("  Matrix size: ", MATRIX_SIZE, " x ", MATRIX_SIZE, "\n", sep = "")
cat("  Count: ", N_MATRICES, "\n", sep = "")

set.seed(42)

generate_cov_matrix <- function(size) {
  A <- matrix(rnorm(size * size), size, size)
  t(A) %*% A + diag(size)
}

tic("Generation time")
matrices <- lapply(1:N_MATRICES, function(i) generate_cov_matrix(MATRIX_SIZE))
toc()

# Warm-up
cat("\nRunning warm-up...\n")
warmup <- solve(matrices[[1]])

# Benchmark
cat("Running benchmark...\n")

tic("Matrix inversion")
results <- lapply(1:N_MATRICES, function(i) {
  solve(matrices[[i]])
})
time_info <- toc(quiet = TRUE)

total_time <- time_info$toc - time_info$tic
avg_time <- total_time / N_MATRICES

# Verify result
verification <- matrices[[1]] %*% results[[1]]
max_error <- max(abs(verification - diag(MATRIX_SIZE)))

# Results
cat("\n")
cat(rep("=", 70), "\n", sep = "")
cat("RESULTS\n")
cat(rep("=", 70), "\n", sep = "")
cat("Total time:        ", round(total_time, 3), " seconds\n", sep = "")
cat("Time per matrix:   ", round(avg_time, 3), " seconds\n", sep = "")
cat("Throughput:        ", round(N_MATRICES / total_time, 2), " matrices/sec\n", sep = "")
cat("Max error:         ", format(max_error, scientific = TRUE), "\n", sep = "")
cat(rep("=", 70), "\n", sep = "")
cat("\n")
