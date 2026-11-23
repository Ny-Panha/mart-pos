<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckRole
{
    public function handle(Request $request, Closure $next, ...$roles): Response
    {
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated',
            ], 401);
        }

        $userRole = strtoupper(trim((string) $user->role));
        $allowedRoles = array_map(fn($r) => strtoupper(trim((string) $r)), $roles);

        if (!in_array($userRole, $allowedRoles, true)) {
            return response()->json([
                'success' => false,
                'message' => "Unauthorized. Role '{$user->role}' cannot perform this action.",
            ], 403);
        }

        return $next($request);
    }
}
