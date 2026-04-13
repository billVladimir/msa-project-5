package com.example.batchprocessing;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.batch.core.Job;
import org.springframework.batch.core.JobParameters;
import org.springframework.batch.core.JobParametersBuilder;
import org.springframework.batch.core.launch.JobLauncher;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/jobs")
public class JobController {

	private static final Logger log = LoggerFactory.getLogger(JobController.class);

	private final JobLauncher jobLauncher;
	private final Job importProductJob;

	public JobController(JobLauncher jobLauncher, Job importProductJob) {
		this.jobLauncher = jobLauncher;
		this.importProductJob = importProductJob;
	}

	@PostMapping("/import-products")
	public ResponseEntity<Map<String, Object>> launchImportProductJob() {
		log.info("Received request to launch importProductJob");
		try {
			JobParameters params = new JobParametersBuilder()
				.addLong("startedAt", System.currentTimeMillis())
				.toJobParameters();

			var execution = jobLauncher.run(importProductJob, params);

			log.info("Job completed with status: {}", execution.getStatus());

			return ResponseEntity.ok(Map.of(
				"status", execution.getStatus().toString(),
				"jobId", execution.getJobId(),
				"startTime", execution.getStartTime().toString(),
				"endTime", execution.getEndTime() != null ? execution.getEndTime().toString() : "N/A"
			));
		} catch (Exception e) {
			log.error("Failed to launch job", e);
			return ResponseEntity.internalServerError().body(Map.of(
				"status", "FAILED",
				"error", e.getMessage()
			));
		}
	}
}
