<?php
// app/Http/Controllers/Api/AuthController.php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $request->validate([
            'name'                  => 'required|string|min:2|max:100',
            'email'                 => 'required|email|unique:users,email',
            'phone'                 => 'required|string|regex:/^[6-9]\d{9}$/|unique:users,phone',
            'password'              => ['required', 'confirmed', Password::min(8)->letters()->numbers()],
            'password_confirmation' => 'required',
        ]);

        $user = User::create([
            'name'     => $request->name,
            'email'    => $request->email,
            'phone'    => $request->phone,
            'password' => Hash::make($request->password),
        ]);

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'message'       => 'Account created successfully.',
            'access_token'  => $token,
            'refresh_token' => null, // Sanctum doesn't use refresh tokens natively
            'token_type'    => 'Bearer',
            'user'          => $user,
        ], 201);
    }

    public function login(Request $request)
    {
        $request->validate([
            'identifier' => 'required|string',
            'password'   => 'required|string',
        ]);

        $identifier = $request->identifier;
        $field = filter_var($identifier, FILTER_VALIDATE_EMAIL) ? 'email' : 'phone';

        $user = User::where($field, $identifier)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json(
                ['message' => 'Invalid credentials. Please check your email/phone and password.'],
                401
            );
        }

        // Revoke old tokens to prevent accumulation
        $user->tokens()->where('name', 'mobile')->delete();

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'message'       => 'Login successful.',
            'access_token'  => $token,
            'refresh_token' => null,
            'token_type'    => 'Bearer',
            'user'          => $user->only(['id', 'name', 'email', 'phone', 'created_at']),
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Logged out successfully.']);
    }

    public function profile(Request $request)
    {
        return response()->json(['data' => $request->user()]);
    }

    public function forgotPassword(Request $request)
    {
        $request->validate(['email' => 'required|email|exists:users,email']);

        \Password::sendResetLink(['email' => $request->email]);

        return response()->json([
            'message' => 'Password reset link sent to your email.',
        ]);
    }
}
