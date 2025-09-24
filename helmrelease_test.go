package tests

import (
	"context"
	"fmt"
	"os"
	"testing"
	"time"

	"managedaks.tests/k8sutils"
	appsv1 "k8s.io/api/apps/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime/schema"
	"k8s.io/client-go/kubernetes"
)

// HelmReleaseChecker encapsulates the logic for checking HelmRelease components
type HelmReleaseChecker struct {
	DynClient  k8sutils.DynamicClient
	Clientset  *kubernetes.Clientset
	Namespace  string
	helmGVR    schema.GroupVersionResource
}

// NewHelmReleaseChecker creates a new instance of HelmReleaseChecker
func NewHelmReleaseChecker(kubeconfig, namespace string) (*HelmReleaseChecker, error) {
	dynClient, err := k8sutils.GetDynamicClient(kubeconfig)
	if err != nil {
		return nil, fmt.Errorf("failed to create dynamic client: %v", err)
	}

	clientset, err := k8sutils.GetClientSet(kubeconfig)
	if err != nil {
		return nil, fmt.Errorf("failed to create clientset: %v", err)
	}

	return &HelmReleaseChecker{
		DynClient: dynClient,
		Clientset: clientset,
		Namespace: namespace,
		helmGVR: schema.GroupVersionResource{
			Group:    "helm.toolkit.fluxcd.io",
			Version:  "v2beta1",
			Resource: "helmreleases",
		},
	}, nil
}

// HelmReleaseResult stores the check results for a HelmRelease
type HelmReleaseResult struct {
	Name         string
	Ready        bool
	Conditions   []ConditionInfo
	TestHooks    []TestHookInfo
	Deployments  []WorkloadStatus
	DaemonSets   []WorkloadStatus
	History      []HistoryEntry
	Error        error
}

// ConditionInfo stores HelmRelease condition details
type ConditionInfo struct {
	Type    string
	Status  string
	Reason  string
	Message string
}

// TestHookInfo stores test hook details
type TestHookInfo struct {
	Type    string
	Status  string
	Message string
}

// WorkloadStatus stores deployment/daemonset status
type WorkloadStatus struct {
	Name        string
	Type        string
	Ready       int32
	Total       int32
	IsHealthy   bool
}

// HistoryEntry stores HelmRelease history information
type HistoryEntry struct {
	Version      int64
	ChartVersion string
	TestHooks    map[string]interface{}
}

// CheckHelmRelease performs comprehensive checks on a single HelmRelease
func (h *HelmReleaseChecker) CheckHelmRelease(ctx context.Context, name string) HelmReleaseResult {
	result := HelmReleaseResult{Name: name}

	// Get HelmRelease resource
	hr, err := h.DynClient.Resource(h.helmGVR).Namespace(h.Namespace).Get(ctx, name, metav1.GetOptions{})
	if err != nil {
		result.Error = fmt.Errorf("failed to get HelmRelease: %v", err)
		return result
	}

	// Extract and check status
	h.extractStatus(hr, &result)

	// Extract history
	h.extractHistory(hr, &result)

	// Check associated deployments
	h.checkDeployments(ctx, name, &result)

	// Check associated daemonsets
	h.checkDaemonSets(ctx, name, &result)

	return result
}

// extractStatus extracts status information from HelmRelease
func (h *HelmReleaseChecker) extractStatus(hr *unstructured.Unstructured, result *HelmReleaseResult) {
	status, found, err := unstructured.NestedMap(hr.Object, "status")
	if err != nil || !found {
		result.Error = fmt.Errorf("status not found or error: %v", err)
		return
	}

	// Extract conditions
	conditions, found, err := unstructured.NestedSlice(status, "conditions")
	if err == nil && found {
		for _, cond := range conditions {
			if condMap, ok := cond.(map[string]interface{}); ok {
				condInfo := ConditionInfo{
					Type:    fmt.Sprintf("%v", condMap["type"]),
					Status:  fmt.Sprintf("%v", condMap["status"]),
					Reason:  fmt.Sprintf("%v", condMap["reason"]),
					Message: fmt.Sprintf("%v", condMap["message"]),
				}
				result.Conditions = append(result.Conditions, condInfo)

				if condInfo.Type == "Ready" && condInfo.Status == "True" {
					result.Ready = true
				}
			}
		}
	}

	// Extract test hooks
	testHooks, found, err := unstructured.NestedSlice(status, "testHooks")
	if err == nil && found {
		for _, hook := range testHooks {
			if hookMap, ok := hook.(map[string]interface{}); ok {
				result.TestHooks = append(result.TestHooks, TestHookInfo{
					Type:    fmt.Sprintf("%v", hookMap["type"]),
					Status:  fmt.Sprintf("%v", hookMap["status"]),
					Message: fmt.Sprintf("%v", hookMap["message"]),
				})
			}
		}
	}
}

// extractHistory extracts history information from HelmRelease
func (h *HelmReleaseChecker) extractHistory(hr *unstructured.Unstructured, result *HelmReleaseResult) {
	history, found, err := unstructured.NestedSlice(hr.Object, "status", "history")
	if err == nil && found && len(history) > 0 {
		for _, hist := range history {
			if histMap, ok := hist.(map[string]interface{}); ok {
				entry := HistoryEntry{}

				if version, ok := histMap["version"].(int64); ok {
					entry.Version = version
				}

				if chartVersion, ok := histMap["chartVersion"].(string); ok {
					entry.ChartVersion = chartVersion
				}

				if testHooks, ok := histMap["testHooks"].(map[string]interface{}); ok {
					entry.TestHooks = testHooks
				}

				result.History = append(result.History, entry)
			}
		}
	}
}

// checkDeployments checks deployments associated with HelmRelease
func (h *HelmReleaseChecker) checkDeployments(ctx context.Context, helmReleaseName string, result *HelmReleaseResult) {
	deployments, err := h.Clientset.AppsV1().Deployments(h.Namespace).List(ctx, metav1.ListOptions{
		LabelSelector: fmt.Sprintf("helm.toolkit.fluxcd.io/name=%s", helmReleaseName),
	})

	if err != nil {
		return // Non-critical error, continue checking
	}

	for _, dep := range deployments.Items {
		status := WorkloadStatus{
			Name:      dep.Name,
			Type:      "Deployment",
			Ready:     dep.Status.ReadyReplicas,
			Total:     dep.Status.Replicas,
			IsHealthy: dep.Status.ReadyReplicas == dep.Status.Replicas,
		}
		result.Deployments = append(result.Deployments, status)
	}
}

// checkDaemonSets checks daemonsets associated with HelmRelease
func (h *HelmReleaseChecker) checkDaemonSets(ctx context.Context, helmReleaseName string, result *HelmReleaseResult) {
	daemonsets, err := h.Clientset.AppsV1().DaemonSets(h.Namespace).List(ctx, metav1.ListOptions{
		LabelSelector: fmt.Sprintf("helm.toolkit.fluxcd.io/name=%s", helmReleaseName),
	})

	if err != nil {
		return // Non-critical error, continue checking
	}

	for _, ds := range daemonsets.Items {
		status := WorkloadStatus{
			Name:      ds.Name,
			Type:      "DaemonSet",
			Ready:     ds.Status.NumberReady,
			Total:     ds.Status.DesiredNumberScheduled,
			IsHealthy: ds.Status.NumberReady == ds.Status.DesiredNumberScheduled,
		}
		result.DaemonSets = append(result.DaemonSets, status)
	}
}

// OutputFormatter handles formatted output of results
type OutputFormatter struct {
	Verbose bool
}

// FormatResult formats a single HelmRelease result
func (f *OutputFormatter) FormatResult(result HelmReleaseResult) string {
	output := fmt.Sprintf("\n━━━ HelmRelease: %s ━━━\n", result.Name)

	if result.Error != nil {
		output += fmt.Sprintf("  ❌ Error: %v\n", result.Error)
		return output
	}

	// Status indicator
	statusIcon := "✅"
	if !result.Ready {
		statusIcon = "❌"
	}
	output += fmt.Sprintf("  %s Status: %s\n", statusIcon, map[bool]string{true: "Ready", false: "Not Ready"}[result.Ready])

	// Conditions
	if len(result.Conditions) > 0 {
		output += "\n  📋 Conditions:\n"
		for _, cond := range result.Conditions {
			icon := "✓"
			if cond.Status != "True" {
				icon = "✗"
			}
			output += fmt.Sprintf("    %s %s: %s (Reason: %s)\n", icon, cond.Type, cond.Status, cond.Reason)
			if f.Verbose && cond.Message != "" && cond.Message != "<nil>" {
				output += fmt.Sprintf("      └─ %s\n", cond.Message)
			}
		}
	}

	// Deployments
	if len(result.Deployments) > 0 {
		output += "\n  🚀 Deployments:\n"
		for _, dep := range result.Deployments {
			icon := "✅"
			if !dep.IsHealthy {
				icon = "⚠️"
			}
			output += fmt.Sprintf("    %s %s: %d/%d replicas ready\n", icon, dep.Name, dep.Ready, dep.Total)
		}
	}

	// DaemonSets
	if len(result.DaemonSets) > 0 {
		output += "\n  🔧 DaemonSets:\n"
		for _, ds := range result.DaemonSets {
			icon := "✅"
			if !ds.IsHealthy {
				icon = "⚠️"
			}
			output += fmt.Sprintf("    %s %s: %d/%d pods ready\n", icon, ds.Name, ds.Ready, ds.Total)
		}
	}

	// Test Hooks
	if len(result.TestHooks) > 0 {
		output += "\n  🧪 Test Hooks:\n"
		for _, hook := range result.TestHooks {
			output += fmt.Sprintf("    • %s: %s\n", hook.Type, hook.Status)
			if f.Verbose && hook.Message != "" && hook.Message != "<nil>" {
				output += fmt.Sprintf("      └─ %s\n", hook.Message)
			}
		}
	}

	// History (if verbose)
	if f.Verbose && len(result.History) > 0 {
		output += "\n  📜 History:\n"
		for i, hist := range result.History {
			if i < 3 { // Show only last 3 entries
				output += fmt.Sprintf("    • Version %d (Chart: %s)\n", hist.Version, hist.ChartVersion)
			}
		}
	}

	return output
}

// FormatSummary formats a summary of all results
func (f *OutputFormatter) FormatSummary(results []HelmReleaseResult) string {
	totalCount := len(results)
	readyCount := 0
	failedComponents := []string{}

	for _, r := range results {
		if r.Ready && r.Error == nil {
			readyCount++
		} else {
			failedComponents = append(failedComponents, r.Name)
		}
	}

	output := "\n" + "═" * 50 + "\n"
	output += fmt.Sprintf("📊 Summary: %d/%d HelmReleases Ready\n", readyCount, totalCount)

	if len(failedComponents) > 0 {
		output += "\n⚠️  Failed/Not Ready Components:\n"
		for _, name := range failedComponents {
			output += fmt.Sprintf("   • %s\n", name)
		}
	} else {
		output += "\n✅ All components are healthy!\n"
	}

	output += "═" * 50 + "\n"
	return output
}

// TestHelmReleaseComponents is the main test function
func TestHelmReleaseComponents(t *testing.T) {
	// Setup
	kubeconfig := os.Getenv("KUBECONFIG")
	if kubeconfig == "" {
		t.Fatal("KUBECONFIG environment variable not set")
	}

	namespace := "uk8s-core"
	checker, err := NewHelmReleaseChecker(kubeconfig, namespace)
	if err != nil {
		t.Fatalf("Failed to initialize HelmRelease checker: %v", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	// List all HelmReleases
	hrList, err := checker.DynClient.Resource(checker.helmGVR).Namespace(namespace).List(ctx, metav1.ListOptions{})
	if err != nil {
		t.Fatalf("Failed to list HelmReleases: %v", err)
	}

	if len(hrList.Items) == 0 {
		t.Skip("No HelmReleases found in namespace")
	}

	// Check each HelmRelease
	formatter := OutputFormatter{Verbose: testing.Verbose()}
	results := []HelmReleaseResult{}

	fmt.Printf("\n🔍 Checking %d HelmRelease(s) in namespace '%s'\n", len(hrList.Items), namespace)

	for _, hr := range hrList.Items {
		name := hr.GetName()
		result := checker.CheckHelmRelease(ctx, name)
		results = append(results, result)

		// Output individual result
		fmt.Print(formatter.FormatResult(result))

		// Mark test failures
		if result.Error != nil {
			t.Errorf("HelmRelease %s encountered error: %v", name, result.Error)
		} else if !result.Ready {
			t.Errorf("HelmRelease %s is not ready", name)
		}

		// Check workloads
		for _, dep := range result.Deployments {
			if !dep.IsHealthy {
				t.Errorf("Deployment %s for HelmRelease %s is not healthy: %d/%d replicas ready",
					dep.Name, name, dep.Ready, dep.Total)
			}
		}

		for _, ds := range result.DaemonSets {
			if !ds.IsHealthy {
				t.Errorf("DaemonSet %s for HelmRelease %s is not healthy: %d/%d pods ready",
					ds.Name, name, ds.Ready, ds.Total)
			}
		}
	}

	// Output summary
	fmt.Print(formatter.FormatSummary(results))
}

// TestSpecificHelmRelease tests a specific HelmRelease component
func TestSpecificHelmRelease(t *testing.T) {
	helmReleaseName := os.Getenv("HELM_RELEASE_NAME")
	if helmReleaseName == "" {
		t.Skip("HELM_RELEASE_NAME not set, skipping specific test")
	}

	kubeconfig := os.Getenv("KUBECONFIG")
	if kubeconfig == "" {
		t.Fatal("KUBECONFIG environment variable not set")
	}

	namespace := "uk8s-core"
	if ns := os.Getenv("NAMESPACE"); ns != "" {
		namespace = ns
	}

	checker, err := NewHelmReleaseChecker(kubeconfig, namespace)
	if err != nil {
		t.Fatalf("Failed to initialize HelmRelease checker: %v", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()

	formatter := OutputFormatter{Verbose: true}
	result := checker.CheckHelmRelease(ctx, helmReleaseName)

	fmt.Print(formatter.FormatResult(result))

	if result.Error != nil {
		t.Fatalf("HelmRelease %s check failed: %v", helmReleaseName, result.Error)
	}

	if !result.Ready {
		t.Errorf("HelmRelease %s is not ready", helmReleaseName)
	}
}