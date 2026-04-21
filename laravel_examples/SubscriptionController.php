<?php
// app/Http/Controllers/Api/SubscriptionController.php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Semester;
use App\Models\Subscription;
use Illuminate\Http\Request;
use Razorpay\Api\Api;
use Razorpay\Api\Errors\SignatureVerificationError;

class SubscriptionController extends Controller
{
    private Api $razorpay;

    public function __construct()
    {
        $this->razorpay = new Api(
            config('services.razorpay.key'),
            config('services.razorpay.secret')
        );
    }

    /**
     * Check if the authenticated user has an active subscription
     * for a given semester.
     */
    public function check(Semester $semester)
    {
        $isSubscribed = Subscription::where('user_id', auth()->id())
            ->where('semester_id', $semester->id)
            ->where('status', 'active')
            ->where('end_date', '>', now())
            ->exists();

        return response()->json(['is_subscribed' => $isSubscribed]);
    }

    /**
     * Create a Razorpay order for a semester subscription.
     */
    public function createOrder(Request $request)
    {
        $request->validate(['semester_id' => 'required|exists:semesters,id']);

        $semesterId = $request->semester_id;

        // Prevent duplicate active subscriptions
        $exists = Subscription::where('user_id', auth()->id())
            ->where('semester_id', $semesterId)
            ->where('status', 'active')
            ->where('end_date', '>', now())
            ->exists();

        if ($exists) {
            return response()->json(
                ['message' => 'You already have an active subscription for this semester.'],
                409
            );
        }

        $order = $this->razorpay->order->create([
            'amount'          => 7500, // ₹75 in paise
            'currency'        => 'INR',
            'receipt'         => 'rcpt_' . auth()->id() . '_' . $semesterId,
            'payment_capture' => 1,
            'notes'           => [
                'user_id'     => auth()->id(),
                'semester_id' => $semesterId,
            ],
        ]);

        return response()->json([
            'order_id' => $order->id,
            'amount'   => $order->amount,
            'currency' => $order->currency,
        ]);
    }

    /**
     * Verify Razorpay payment signature and activate subscription.
     */
    public function verifyPayment(Request $request)
    {
        $request->validate([
            'semester_id'          => 'required|exists:semesters,id',
            'razorpay_order_id'    => 'required|string',
            'razorpay_payment_id'  => 'required|string',
            'razorpay_signature'   => 'required|string',
        ]);

        try {
            $this->razorpay->utility->verifyPaymentSignature([
                'razorpay_order_id'   => $request->razorpay_order_id,
                'razorpay_payment_id' => $request->razorpay_payment_id,
                'razorpay_signature'  => $request->razorpay_signature,
            ]);
        } catch (SignatureVerificationError $e) {
            return response()->json(
                ['message' => 'Payment verification failed. Contact support.'],
                400
            );
        }

        $subscription = Subscription::create([
            'user_id'              => auth()->id(),
            'semester_id'          => $request->semester_id,
            'razorpay_order_id'    => $request->razorpay_order_id,
            'razorpay_payment_id'  => $request->razorpay_payment_id,
            'razorpay_signature'   => $request->razorpay_signature,
            'status'               => 'active',
            'start_date'           => now(),
            'end_date'             => now()->addMonths(6),
            'amount'               => 7500,
        ]);

        return response()->json([
            'message'      => 'Subscription activated successfully.',
            'subscription' => $subscription,
        ]);
    }

    /**
     * List all subscriptions for the authenticated user.
     */
    public function mySubscriptions()
    {
        $subscriptions = Subscription::where('user_id', auth()->id())
            ->orderByDesc('created_at')
            ->get();

        return response()->json(['data' => $subscriptions]);
    }
}
