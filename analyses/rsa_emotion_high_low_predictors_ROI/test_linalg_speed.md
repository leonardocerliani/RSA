Test Linear Algebra Speed with Thread Control
================

<!-- 
==============================================================================
HOW TO RUN:
==============================================================================

1. Set environment variables and run:
   n=20
   export OPENBLAS_NUM_THREADS=$n OMP_NUM_THREADS=$n MKL_NUM_THREADS=$n
   Rscript -e "rmarkdown::render('test_linalg_speed.Rmd', quiet = FALSE)"

2. Or in one line:
   n=20 && export OPENBLAS_NUM_THREADS=$n OMP_NUM_THREADS=$n MKL_NUM_THREADS=$n && Rscript -e "rmarkdown::render('test_linalg_speed.Rmd', quiet = FALSE)"

3. To test different thread counts:
   for n in 1 2 4 8 20; do
     export OPENBLAS_NUM_THREADS=$n OMP_NUM_THREADS=$n MKL_NUM_THREADS=$n
     echo "=== Testing with $n threads ==="
     Rscript -e "rmarkdown::render('test_linalg_speed.Rmd', quiet = FALSE)"
   done

==============================================================================
-->

``` r
# ==============================================================================
# Test Linear Algebra Speed with Thread Control
# ==============================================================================

# Parameters
MATRIX_SIZE <- 1000
N_MATRICES <- 100
N_CORES <- 20

cat("\n")
```

``` r
cat(rep("=", 70), "\n", sep = "")
```

    ## ======================================================================

``` r
cat("Linear Algebra Performance Test\n")
```

    ## Linear Algebra Performance Test

``` r
cat(rep("=", 70), "\n", sep = "")
```

    ## ======================================================================

``` r
# Load library
suppressPackageStartupMessages({
  library(tictoc)
})

# Generate covariance matrices
cat("\nGenerating matrices:\n")
```

    ## 
    ## Generating matrices:

``` r
cat("  Matrix size: ", MATRIX_SIZE, " x ", MATRIX_SIZE, "\n", sep = "")
```

    ##   Matrix size: 1000 x 1000

``` r
cat("  Count: ", N_MATRICES, "\n", sep = "")
```

    ##   Count: 100

``` r
set.seed(42)

generate_cov_matrix <- function(size) {
  A <- matrix(rnorm(size * size), size, size)
  t(A) %*% A + diag(size)
}

tic("Generation time")
matrices <- lapply(1:N_MATRICES, function(i) generate_cov_matrix(MATRIX_SIZE))
toc()
```

    ## Generation time: 7.553 sec elapsed

``` r
# Warm-up
cat("\nRunning warm-up...\n")
```

    ## 
    ## Running warm-up...

``` r
warmup <- solve(matrices[[1]])

# Benchmark
cat("Running benchmark...\n")
```

    ## Running benchmark...

``` r
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
```

``` r
cat(rep("=", 70), "\n", sep = "")
```

    ## ======================================================================

``` r
cat("RESULTS\n")
```

    ## RESULTS

``` r
cat(rep("=", 70), "\n", sep = "")
```

    ## ======================================================================

``` r
cat("Total time:        ", round(total_time, 3), " seconds\n", sep = "")
```

    ## Total time:        2.735 seconds

``` r
cat("Time per matrix:   ", round(avg_time, 3), " seconds\n", sep = "")
```

    ## Time per matrix:   0.027 seconds

``` r
cat("Throughput:        ", round(N_MATRICES / total_time, 2), " matrices/sec\n", sep = "")
```

    ## Throughput:        36.56 matrices/sec

``` r
cat("Max error:         ", format(max_error, scientific = TRUE), "\n", sep = "")
```

    ## Max error:         8.526513e-14

``` r
cat(rep("=", 70), "\n", sep = "")
```

    ## ======================================================================

``` r
cat("\n")
```
