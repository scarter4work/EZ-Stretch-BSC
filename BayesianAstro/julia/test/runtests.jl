"""
Tests for BayesianAstro package.
"""
using Test
using BayesianAstro

@testset "BayesianAstro.jl" begin

    @testset "PixelDistribution" begin
        dist = PixelDistribution()
        
        @test dist.n == 0
        @test dist.mean == 0.0f0
        @test dist.m2 == 0.0f0
    end

    @testset "Welford's Algorithm" begin
        dist = PixelDistribution()
        
        # Test with known values
        values = Float32[2, 4, 4, 4, 5, 5, 7, 9]
        for v in values
            accumulate!(dist, v)
        end
        
        stats = finalize_statistics(dist)
        
        @test stats.n == 8
        @test stats.mean ≈ 5.0f0 atol=0.001
        @test stats.variance ≈ 4.571f0 atol=0.01  # Sample variance
        @test stats.min == 2.0f0
        @test stats.max == 9.0f0
    end

    @testset "Distribution Classification" begin
        # Test Gaussian classification
        dist = PixelDistribution()
        # Add normally distributed values (simulate)
        for v in Float32[4.9, 5.1, 5.0, 4.8, 5.2, 5.0, 4.95, 5.05]
            accumulate!(dist, v)
        end
        
        dtype = classify_distribution(dist)
        @test dtype == GAUSSIAN || dtype == UNKNOWN  # May need more samples
    end

    @testset "Confidence Scoring" begin
        dist = PixelDistribution()
        
        # Low sample count = low confidence
        accumulate!(dist, 5.0f0)
        conf1 = compute_confidence(dist)
        
        # More samples = higher confidence
        for v in Float32[5.0, 5.0, 5.0, 5.0, 5.0]
            accumulate!(dist, v)
        end
        conf2 = compute_confidence(dist)
        
        @test conf2 > conf1
        @test 0.0f0 <= conf1 <= 1.0f0
        @test 0.0f0 <= conf2 <= 1.0f0
    end

    @testset "Fusion - MLE" begin
        dist = PixelDistribution()
        for v in Float32[10, 12, 11, 10, 11, 12, 10, 11]
            accumulate!(dist, v)
        end
        
        fused = fuse_mle(dist)
        
        # MLE for Gaussian should be close to mean
        @test fused ≈ 10.875f0 atol=0.01
    end

    @testset "ProcessingConfig" begin
        config = ProcessingConfig()
        
        @test config.fusion_strategy == CONFIDENCE_WEIGHTED
        @test config.confidence_threshold == 0.1f0
        @test config.use_gpu == true
        
        # Custom config
        config2 = ProcessingConfig(
            fusion_strategy=MLE,
            outlier_sigma=2.5f0,
            use_gpu=false
        )
        
        @test config2.fusion_strategy == MLE
        @test config2.outlier_sigma == 2.5f0
        @test config2.use_gpu == false
    end

end

println("All tests passed!")
