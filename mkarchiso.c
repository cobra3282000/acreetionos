/*
 * mkarchiso - Colorful C wrapper for mkarchiso
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * A vibrant, colorful wrapper around the archiso build system
 */

#define _POSIX_C_SOURCE 200809L

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include <time.h>
#include <errno.h>

// ANSI Color codes - making it COLORFUL!
#define COLOR_RESET         "\033[0m"
#define COLOR_BOLD          "\033[1m"
#define COLOR_DIM           "\033[2m"
#define COLOR_ITALIC        "\033[3m"
#define COLOR_UNDERLINE     "\033[4m"
#define COLOR_BLINK         "\033[5m"

// Foreground colors
#define COLOR_BLACK         "\033[30m"
#define COLOR_RED           "\033[31m"
#define COLOR_GREEN         "\033[32m"
#define COLOR_YELLOW        "\033[33m"
#define COLOR_BLUE          "\033[34m"
#define COLOR_MAGENTA       "\033[35m"
#define COLOR_CYAN          "\033[36m"
#define COLOR_WHITE         "\033[37m"

// Bright foreground colors
#define COLOR_BRIGHT_BLACK   "\033[90m"
#define COLOR_BRIGHT_RED     "\033[91m"
#define COLOR_BRIGHT_GREEN   "\033[92m"
#define COLOR_BRIGHT_YELLOW  "\033[93m"
#define COLOR_BRIGHT_BLUE    "\033[94m"
#define COLOR_BRIGHT_MAGENTA "\033[95m"
#define COLOR_BRIGHT_CYAN    "\033[96m"
#define COLOR_BRIGHT_WHITE   "\033[97m"

// Background colors
#define BG_BLACK            "\033[40m"
#define BG_RED              "\033[41m"
#define BG_GREEN            "\033[42m"
#define BG_YELLOW           "\033[43m"
#define BG_BLUE             "\033[44m"
#define BG_MAGENTA          "\033[45m"
#define BG_CYAN             "\033[46m"
#define BG_WHITE            "\033[47m"

// Program info
#define PROGRAM_NAME "mkarchiso"
#define VERSION "1.0.0"

// Function prototypes
void print_banner(void);
void print_info(const char *message);
void print_success(const char *message);
void print_warning(const char *message);
void print_error(const char *message);
void print_step(const char *message);
void print_usage(void);
void print_separator(void);
char* get_timestamp(void);
void draw_progress_bar(int percentage, const char *label);
void draw_iso_write_progress(const char *buffer);

int main(int argc, char *argv[]) {
    char command[4096] = "/usr/bin/mkarchiso";
    char full_command[8192];
    char iso_output_dir[512] = "../ISO";  // Default
    char error_list[10][1024];  // Store up to 10 errors
    int error_count = 0;
    int build_stage = 0;  // Track build stages for progress
    int i;
    int status;
    FILE *fp;
    char buffer[1024];

    // Print awesome banner
    print_banner();

    // Build the command with all arguments and extract output directory
    for (i = 1; i < argc; i++) {
        // Check for -o flag to get output directory
        if (strcmp(argv[i], "-o") == 0 && i + 1 < argc) {
            strncpy(iso_output_dir, argv[i + 1], sizeof(iso_output_dir) - 1);
        }

        strcat(command, " ");
        // Check if argument contains spaces and quote if needed
        if (strchr(argv[i], ' ') != NULL) {
            strcat(command, "\"");
            strcat(command, argv[i]);
            strcat(command, "\"");
        } else {
            strcat(command, argv[i]);
        }
    }

    // Show what we're doing
    print_separator();
    print_step("Preparing AcreetionOS build environment");
    printf("%s%s[%s] %sCommand:%s %s%s\n",
           COLOR_DIM, COLOR_CYAN, get_timestamp(),
           COLOR_BRIGHT_YELLOW, COLOR_RESET,
           COLOR_WHITE, command);
    print_separator();

    // Add 2>&1 to capture both stdout and stderr
    snprintf(full_command, sizeof(full_command), "%s 2>&1", command);

    // Execute mkarchiso and capture output
    print_step("Launching mkarchiso build process");
    printf("\n");

    fp = popen(full_command, "r");
    if (fp == NULL) {
        print_error("Failed to execute mkarchiso!");
        fprintf(stderr, "%s%sError: %s%s\n", COLOR_BOLD, COLOR_RED, strerror(errno), COLOR_RESET);
        return 1;
    }

    // Read and colorize output line by line
    while (fgets(buffer, sizeof(buffer), fp) != NULL) {
        // Remove trailing newline if present
        size_t len = strlen(buffer);
        if (len > 0 && buffer[len-1] == '\n') {
            buffer[len-1] = '\0';
        }

        // Track build stages for progress bar
        if (strstr(buffer, "Installing packages")) {
            build_stage = 1;
        } else if (strstr(buffer, "Copying custom airootfs")) {
            build_stage = 2;
        } else if (strstr(buffer, "Creating SquashFS") || strstr(buffer, "Creating EROFS") || strstr(buffer, "Creating ext4")) {
            build_stage = 3;
        } else if (strstr(buffer, "Creating checksum")) {
            build_stage = 4;
        } else if (strstr(buffer, "xorriso") && strstr(buffer, "version")) {
            // xorriso starting - beginning of ISO creation
            build_stage = 5;
        } else if (strstr(buffer, "UPDATE :") && strstr(buffer, "% done")) {
            // xorriso progress update - show real-time progress
            build_stage = 5;
            draw_iso_write_progress(buffer);
        } else if (strstr(buffer, "isohybrid")) {
            build_stage = 6;
        }

        // Colorize based on content
        if (strstr(buffer, "ERROR") || strstr(buffer, "Error") || strstr(buffer, "error")) {
            printf("%s%s✗ %s%s\n", COLOR_BOLD, COLOR_RED, buffer, COLOR_RESET);
            // Store error for summary (max 10 errors)
            if (error_count < 10) {
                strncpy(error_list[error_count], buffer, sizeof(error_list[0]) - 1);
                error_count++;
            }
        }
        else if (strstr(buffer, "WARNING") || strstr(buffer, "Warning") || strstr(buffer, "warning")) {
            printf("%s%s⚠ %s%s\n", COLOR_BOLD, COLOR_YELLOW, buffer, COLOR_RESET);
        }
        else if (strstr(buffer, "INFO") || strstr(buffer, "Info")) {
            printf("%s%s➜ %s%s\n", COLOR_BOLD, COLOR_CYAN, buffer, COLOR_RESET);
        }
        else if (strstr(buffer, "Done!") || strstr(buffer, "successfully")) {
            printf("%s%s✓ %s%s\n", COLOR_BOLD, COLOR_GREEN, buffer, COLOR_RESET);
        }
        else if (strstr(buffer, "Creating") || strstr(buffer, "Building") || strstr(buffer, "Installing")) {
            printf("%s%s⚙ %s%s\n", COLOR_BOLD, COLOR_MAGENTA, buffer, COLOR_RESET);
        }
        else if (strstr(buffer, "Copying") || strstr(buffer, "Preparing")) {
            printf("%s%s📦 %s%s\n", COLOR_BOLD, COLOR_BLUE, buffer, COLOR_RESET);
        }
        else {
            // Default output with subtle color
            printf("%s%s%s\n", COLOR_WHITE, buffer, COLOR_RESET);
        }

        // Update progress bar at bottom based on current stage (only when stage changes)
        static int last_stage = 0;
        if (build_stage > 0 && build_stage != last_stage) {
            int percentage = 0;
            const char *stage_label = "";

            switch(build_stage) {
                case 1:
                    percentage = 15;
                    stage_label = "Installing packages";
                    break;
                case 2:
                    percentage = 35;
                    stage_label = "Copying custom files";
                    break;
                case 3:
                    percentage = 55;
                    stage_label = "Creating filesystem image";
                    break;
                case 4:
                    percentage = 70;
                    stage_label = "Creating checksums";
                    break;
                case 5:
                    percentage = 85;
                    stage_label = "Writing ISO to disk";
                    break;
                case 6:
                    percentage = 95;
                    stage_label = "Finalizing ISO";
                    break;
            }

            draw_progress_bar(percentage, stage_label);
            last_stage = build_stage;
        }

        fflush(stdout);
    }

    // Show completion progress bar
    if (build_stage > 0) {
        draw_progress_bar(100, "Build complete");
        printf("\n");  // Extra newline after completion
    }

    // Get exit status
    status = pclose(fp);

    // Clear screen for final summary
    printf("\033[2J\033[H");  // Clear screen and move to top

    printf("\n");
    print_separator();

    if (WIFEXITED(status)) {
        int exit_status = WEXITSTATUS(status);
        if (exit_status == 0) {
            print_success("Build completed successfully!");
            printf("\n%s%s", COLOR_BRIGHT_GREEN, COLOR_BOLD);
            printf("    ╔═══════════════════════════════════════════════╗\n");
            printf("    ║      ✓ AcreetionOS ISO Build Complete!       ║\n");
            printf("    ╚═══════════════════════════════════════════════╝\n");
            printf("%s\n", COLOR_RESET);

            // Show ISO location
            printf("%s%s📦 ISO Output Directory:%s %s%s%s\n",
                   COLOR_BOLD, COLOR_BRIGHT_CYAN, COLOR_RESET,
                   COLOR_BRIGHT_YELLOW, iso_output_dir, COLOR_RESET);

            // Try to find and display the actual ISO file
            char find_cmd[1024];
            snprintf(find_cmd, sizeof(find_cmd), "ls -lh %s/*.iso 2>/dev/null | tail -1", iso_output_dir);
            FILE *iso_fp = popen(find_cmd, "r");
            if (iso_fp != NULL) {
                char iso_info[512];
                if (fgets(iso_info, sizeof(iso_info), iso_fp) != NULL) {
                    printf("%s%s📀 ISO File:%s %s%s\n",
                           COLOR_BOLD, COLOR_BRIGHT_CYAN, COLOR_RESET,
                           COLOR_WHITE, iso_info);
                }
                pclose(iso_fp);
            }

            printf("\n");
            return 0;
        } else {
            print_error("Build failed with errors!");
            printf("%s%sExit code: %d%s\n\n", COLOR_BOLD, COLOR_RED, exit_status, COLOR_RESET);

            // List all errors encountered
            if (error_count > 0) {
                printf("%s%s❌ Errors Encountered (%d):%s\n",
                       COLOR_BOLD, COLOR_BRIGHT_RED, error_count, COLOR_RESET);
                print_separator();
                for (i = 0; i < error_count; i++) {
                    printf("%s%d.%s %s%s%s\n",
                           COLOR_BRIGHT_RED, i + 1, COLOR_RESET,
                           COLOR_RED, error_list[i], COLOR_RESET);
                }
                print_separator();
            }

            return exit_status;
        }
    } else {
        print_error("Build process terminated abnormally!");
        return 1;
    }
}

void print_banner(void) {
    printf("\n%s%s", COLOR_BOLD, COLOR_BRIGHT_CYAN);
    printf("╔════════════════════════════════════════════════════════════╗\n");
    printf("║                                                            ║\n");
    printf("║  %s███╗   ███╗██╗  ██╗ █████╗ ██████╗  ██████╗██╗  ██╗██╗███████╗ ██████╗ %s║\n", COLOR_BRIGHT_MAGENTA, COLOR_BRIGHT_CYAN);
    printf("║  %s████╗ ████║██║ ██╔╝██╔══██╗██╔══██╗██╔════╝██║  ██║██║██╔════╝██╔═══██╗%s║\n", COLOR_BRIGHT_MAGENTA, COLOR_BRIGHT_CYAN);
    printf("║  %s██╔████╔██║█████╔╝ ███████║██████╔╝██║     ███████║██║███████╗██║   ██║%s║\n", COLOR_BRIGHT_MAGENTA, COLOR_BRIGHT_CYAN);
    printf("║  %s██║╚██╔╝██║██╔═██╗ ██╔══██║██╔══██╗██║     ██╔══██║██║╚════██║██║   ██║%s║\n", COLOR_BRIGHT_MAGENTA, COLOR_BRIGHT_CYAN);
    printf("║  %s██║ ╚═╝ ██║██║  ██╗██║  ██║██║  ██║╚██████╗██║  ██║██║███████║╚██████╔╝%s║\n", COLOR_BRIGHT_MAGENTA, COLOR_BRIGHT_CYAN);
    printf("║  %s╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝╚══════╝ ╚═════╝ %s║\n", COLOR_BRIGHT_MAGENTA, COLOR_BRIGHT_CYAN);
    printf("║                                                            ║\n");
    printf("║          %sAcreetionOS ISO Build System - v%s%s           ║\n", COLOR_BRIGHT_YELLOW, VERSION, COLOR_BRIGHT_CYAN);
    printf("║              %sColorful C Wrapper Edition%s               ║\n", COLOR_BRIGHT_GREEN, COLOR_BRIGHT_CYAN);
    printf("║                                                            ║\n");
    printf("╚════════════════════════════════════════════════════════════╝\n");
    printf("%s\n", COLOR_RESET);
}

void print_separator(void) {
    printf("%s%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n",
           COLOR_DIM, COLOR_CYAN, COLOR_RESET);
}

void print_info(const char *message) {
    printf("%s%s[INFO]%s %s%s%s\n",
           COLOR_BOLD, COLOR_BRIGHT_CYAN, COLOR_RESET,
           COLOR_WHITE, message, COLOR_RESET);
}

void print_success(const char *message) {
    printf("%s%s[SUCCESS]%s %s✓ %s%s\n",
           COLOR_BOLD, COLOR_BRIGHT_GREEN, COLOR_RESET,
           COLOR_GREEN, message, COLOR_RESET);
}

void print_warning(const char *message) {
    printf("%s%s[WARNING]%s %s⚠ %s%s\n",
           COLOR_BOLD, COLOR_BRIGHT_YELLOW, COLOR_RESET,
           COLOR_YELLOW, message, COLOR_RESET);
}

void print_error(const char *message) {
    printf("%s%s[ERROR]%s %s✗ %s%s\n",
           COLOR_BOLD, COLOR_BRIGHT_RED, COLOR_RESET,
           COLOR_RED, message, COLOR_RESET);
}

void print_step(const char *message) {
    printf("%s%s[STEP]%s %s▶ %s%s\n",
           COLOR_BOLD, COLOR_BRIGHT_MAGENTA, COLOR_RESET,
           COLOR_MAGENTA, message, COLOR_RESET);
}

char* get_timestamp(void) {
    static char timestamp[32];
    time_t now = time(NULL);
    struct tm *t = localtime(&now);
    strftime(timestamp, sizeof(timestamp), "%H:%M:%S", t);
    return timestamp;
}

void draw_progress_bar(int percentage, const char *label) {
    int bar_width = 50;
    int filled = (bar_width * percentage) / 100;
    int i;

    // Just print the progress bar on a new line - simpler and more reliable
    printf("\n%s%s[PROGRESS]%s ", COLOR_BOLD, COLOR_BRIGHT_CYAN, COLOR_RESET);

    // Draw the progress bar
    printf("[");
    for (i = 0; i < bar_width; i++) {
        if (i < filled) {
            if (percentage < 33) {
                printf("%s█%s", COLOR_BRIGHT_RED, COLOR_RESET);
            } else if (percentage < 66) {
                printf("%s█%s", COLOR_BRIGHT_YELLOW, COLOR_RESET);
            } else {
                printf("%s█%s", COLOR_BRIGHT_GREEN, COLOR_RESET);
            }
        } else {
            printf("%s░%s", COLOR_DIM, COLOR_RESET);
        }
    }
    printf("] ");

    // Show percentage
    if (percentage < 33) {
        printf("%s%s%3d%%%s", COLOR_BOLD, COLOR_BRIGHT_RED, percentage, COLOR_RESET);
    } else if (percentage < 66) {
        printf("%s%s%3d%%%s", COLOR_BOLD, COLOR_BRIGHT_YELLOW, percentage, COLOR_RESET);
    } else {
        printf("%s%s%3d%%%s", COLOR_BOLD, COLOR_BRIGHT_GREEN, percentage, COLOR_RESET);
    }

    // Show label
    printf(" %s%s%s\n", COLOR_CYAN, label, COLOR_RESET);

    fflush(stdout);
}

void draw_iso_write_progress(const char *buffer) {
    // Extract percentage from xorriso UPDATE output
    // Format: "UPDATE : 25.50% done, estimate finish ..."
    float percent_float;
    int percentage;
    static int last_iso_percent = -1;

    // Only process if this is actually an UPDATE line with % done
    if (strstr(buffer, "UPDATE :") && strstr(buffer, "% done")) {
        // Try to extract the percentage using sscanf
        if (sscanf(buffer, "%*[^0-9]%f%%", &percent_float) == 1) {
            percentage = (int)percent_float;

            // Only show if it's a different percentage than last time (avoid duplicates)
            if (percentage >= 0 && percentage <= 100 && percentage != last_iso_percent) {
                // Show every 5% to give better feedback
                if (percentage % 5 == 0 || percentage == 100) {
                    draw_progress_bar(percentage, "Writing ISO to disk");
                    last_iso_percent = percentage;
                }
            }
        }
    }
}

void print_usage(void) {
    printf("%s%sUsage:%s %s [mkarchiso options]%s\n\n",
           COLOR_BOLD, COLOR_CYAN, COLOR_RESET,
           PROGRAM_NAME, COLOR_RESET);
    printf("This is a colorful wrapper around the standard mkarchiso tool.\n");
    printf("All arguments are passed directly to /usr/bin/mkarchiso\n\n");
    printf("%sExample:%s\n", COLOR_BOLD, COLOR_RESET);
    printf("  %s -L AcreetionOS -v -o ../ISO . -C ./pacman.conf\n\n", PROGRAM_NAME);
}
