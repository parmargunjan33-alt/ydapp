<?php
// app/Http/Controllers/Api/OldPaperController.php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\OldPaper;
use App\Models\Semester;
use App\Models\Subscription;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class OldPaperController extends Controller
{
    /**
     * List old papers for a semester.
     * Returns basic info only — no PDF URL at this stage.
     */
    public function index(Semester $semester)
    {
        $papers = $semester->oldPapers()
            ->orderByDesc('year')
            ->get(['id', 'semester_id', 'title', 'subject', 'year', 'pages_count', 'created_at']);

        return response()->json(['data' => $papers]);
    }

    /**
     * Return a signed temporary URL for viewing a PDF.
     * Subscribed users get 30 min; preview gets 5 min (first 3 pages only enforced client-side).
     */
    public function viewUrl(OldPaper $paper)
    {
        $isSubscribed = Subscription::where('user_id', auth()->id())
            ->where('semester_id', $paper->semester_id)
            ->where('status', 'active')
            ->where('end_date', '>', now())
            ->exists();

        $expiresAt = $isSubscribed
            ? now()->addMinutes(30)
            : now()->addMinutes(5);

        // Use S3 signed URL in production
        if (config('filesystems.default') === 's3') {
            $url = Storage::temporaryUrl(
                $paper->pdf_path,
                $expiresAt,
                [
                    'ResponseContentType'        => 'application/pdf',
                    'ResponseContentDisposition' => 'inline',
                ]
            );
        } else {
            // Local disk — generate a signed route
            $url = route('papers.serve', [
                'paper'     => $paper->id,
                'token'     => encrypt(['paper_id' => $paper->id, 'exp' => $expiresAt->timestamp]),
                'subscribed' => $isSubscribed ? '1' : '0',
            ]);
        }

        return response()->json([
            'url'           => $url,
            'is_subscribed' => $isSubscribed,
            'expires_in'    => $isSubscribed ? 1800 : 300,
        ]);
    }
}
